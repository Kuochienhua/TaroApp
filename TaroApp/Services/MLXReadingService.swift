import Foundation
import Combine
import Darwin
import Hub
import MLXLLM
import MLXLMCommon

/// Streaming tarot interpretation service.
/// Uses Qwen2.5-1.5B on-device via MLX Swift for free, offline AI interpretation.
/// Falls back to the enhanced local engine if the model is not yet loaded.
@MainActor
final class MLXReadingService: ObservableObject {

    static let shared = MLXReadingService()

    // MARK: - Published

    @Published var isGenerating      = false
    @Published var readingSource: ReadingSource = .local
    @Published var modelState: ModelState = .idle
    /// 0.0–1.0 during HuggingFace download; forwarded to ModelDownloadManager banner.
    @Published var downloadProgress: Double = 0

    // MARK: - Types

    enum ReadingSource: Equatable {
        case local
        case onDeviceAI

        var label: String {
            switch self {
            case .local:      return "本地解讀"
            case .onDeviceAI: return "AI 深度解讀"
            }
        }

        var icon: String {
            switch self {
            case .local:      return "◈"
            case .onDeviceAI: return "✦"
            }
        }
    }

    enum ModelState: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    enum InterpretMode {
        case overall
        case single(Int)
    }

    // MARK: - Private

    private(set) var modelContainer: ModelContainer?

    /// Qwen2.5-1.5B-Instruct 4-bit quantised — best small model for Traditional Chinese
    /// MLX Swift downloads from HuggingFace Hub automatically on first loadContainer() call.
    private let modelConfig = ModelConfiguration(id: "mlx-community/Qwen2.5-1.5B-Instruct-4bit")

    /// Custom HubApi that always attempts network downloads.
    /// useOfflineMode: false overrides the NetworkMonitor which incorrectly
    /// reports "offline" on iOS simulator and some devices.
    private let hubApi = HubApi(
        downloadBase: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first,
        useOfflineMode: false
    )

    private init() {
        // Auto-load only when safetensors weights are already on disk (instant load).
        // A directory alone (from a previous aborted download) is not enough.
        if isModelCached {
            Task { await loadModel() }
        }
    }

    // MARK: - Cache check

    /// Returns true only when at least one `.safetensors` weight file is present under
    /// the same Caches directory that hubApi uses.
    var isModelCached: Bool {
        let cacheDir = modelConfig.modelDirectory(hub: hubApi)
        guard let enumerator = FileManager.default.enumerator(
            at: cacheDir, includingPropertiesForKeys: nil
        ) else { return false }
        return enumerator.contains { ($0 as? URL)?.pathExtension == "safetensors" }
    }

    // MARK: - Model loading

    func loadModel() async {
        guard modelState != .ready, modelState != .loading else { return }
        modelState = .loading
        downloadProgress = 0

        // Hub's NetworkStateActor defaults isConnected=false until NWPathMonitor fires
        // its first async callback (~100-500ms). If loadModel() is called before that
        // update arrives, shouldUseOfflineMode() returns true even on a live connection.
        // CI_DISABLE_NETWORK_MONITOR bypasses the NWPathMonitor check in the Hub library.
        // ProcessInfo.processInfo.environment reads live from the C environment on Darwin,
        // so setenv() after launch is effective.
        setenv("CI_DISABLE_NETWORK_MONITOR", "1", 1)

        do {
            modelContainer = try await LLMModelFactory.shared.loadContainer(
                hub: hubApi,
                configuration: modelConfig,
                progressHandler: { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.downloadProgress = progress.fractionCompleted
                    }
                }
            )
            downloadProgress = 1
            modelState = .ready
        } catch {
            // Print the full error so it's visible in Xcode console for diagnosis.
            print("⚠️ MLX loadModel failed: \(error)")
            modelState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Public: streaming interpretation

    func interpretStream(cards: [DrawnCard], mode: InterpretMode, question: String = "") -> AsyncStream<String> {
        AsyncStream { continuation in
            Task { [weak self] in
                guard let self else { continuation.finish(); return }

                await MainActor.run { self.isGenerating = true }

                // Use MLX if model is ready, otherwise fall back to local engine
                if self.modelState == .ready, let container = self.modelContainer {
                    await self.streamFromMLX(
                        container: container,
                        cards: cards,
                        mode: mode,
                        question: question,
                        continuation: continuation
                    )
                } else {
                    await self.streamLocally(cards: cards, mode: mode, continuation: continuation)
                }

                await MainActor.run { self.isGenerating = false }
                continuation.finish()
            }
        }
    }

    // MARK: - MLX inference (Phase B)

    private func streamFromMLX(
        container: ModelContainer,
        cards: [DrawnCard],
        mode: InterpretMode,
        question: String = "",
        continuation: AsyncStream<String>.Continuation
    ) async {
        await MainActor.run { self.readingSource = .onDeviceAI }

        let (systemPrompt, userPrompt) = buildMLXPrompt(cards: cards, mode: mode, question: question)

        // ChatSession owns the KVCache and calls container.perform internally.
        let session = ChatSession(
            container,
            instructions: systemPrompt,
            generateParameters: GenerateParameters(temperature: 0.8)
        )

        do {
            for try await chunk in session.streamResponse(to: userPrompt) {
                guard !Task.isCancelled else { break }
                continuation.yield(chunk)
            }
        } catch {
            // MLX inference failed — fall back to local engine
            await streamLocally(cards: cards, mode: mode, continuation: continuation)
        }
    }

    // MARK: - Local fallback engine (Phase A)

    private func streamLocally(
        cards: [DrawnCard],
        mode: InterpretMode,
        continuation: AsyncStream<String>.Continuation
    ) async {
        await MainActor.run { self.readingSource = .local }

        let text = generateLocally(cards: cards, mode: mode)
        for char in text {
            guard !Task.isCancelled else { break }
            continuation.yield(String(char))
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    // MARK: - MLX prompt construction
    // Returns (systemInstructions, userMessage) — passed separately to ChatSession
    // so the model's own chat template handles formatting rather than hard-coded tags.

    private func buildMLXPrompt(cards: [DrawnCard], mode: InterpretMode, question: String = "") -> (String, String) {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespaces)
        let hasQuestion = !trimmedQuestion.isEmpty

        // Question constraint injected into system prompt so the model treats it
        // as a hard rule, not just soft context from the user turn.
        let questionConstraint = hasQuestion
            ? """

            【核心任務——絕對不能離題】
            問卜者帶著一個明確的問題來尋求解答：「\(trimmedQuestion)」
            你的每一句話都必須直接回應這個問題。
            - 解讀每張牌時，先問自己：「這對他的問題有什麼意義？」
            - 禁止泛泛而談牌的一般意義，所有解讀必須扣回問題
            - 最終建議必須是針對這個問題可以立刻採取的行動
            """
            : ""

        let system = """
        你是一位擁有二十年經驗的塔羅牌大師，以繁體中文回應。
        你對每一張牌的象徵與能量瞭若指掌，但你從不背誦牌義——你把牌的訊息轉化成對方此刻真正需要聽到的話。

        【你的說話方式】
        - 像老朋友一樣說話：自然、口語、有溫度，不用艱澀術語
        - 把牌面的制式字義「翻譯」成有意義的生活語言，讓對方一聽就懂
        - 直接說重點，不拐彎抹角，不說模稜兩可的話
        - 正面積極：從支持與希望的角度出發，讓對方感到有力量去面對
        - 誠實但貼心：若牌透露出風險或需要注意的地方，清楚說出來，語氣像在提醒好朋友，不是在嚇人

        【解讀方式】
        每張牌請用自然對話的語氣說明：
        1. 這張牌的訊息用一兩句話說清楚（完全口語化，不引用制式牌義）
        2. 針對對方的問題，這張牌帶來什麼正面的啟示或機會
        3. 有沒有需要留意的地方（如果有，溫和但明確地說）
        4. 一個立刻可以做的具體行動建議\(questionConstraint)
        """

        switch mode {
        case .overall:
            guard !cards.isEmpty else { return (system, "") }
            let cardDescriptions = cards.map { dc -> String in
                let meaning = dc.isReversed ? dc.card.reversed : dc.card.upright
                return """
                【\(dc.position)：\(dc.card.name)（\(dc.isReversed ? "逆位" : "正位")）】
                元素：\(dc.card.element)，關鍵詞：\(dc.card.keywords.joined(separator: "、"))
                牌義參考：\(meaning.general)
                """
            }.joined(separator: "\n\n")

            let spreadLabel = cards.count == 1 ? "單張指引" :
                              cards.count == 3 ? "三牌陣" : "\(cards.count)張牌陣"
            let questionHeader = hasQuestion
                ? "問卜者的問題：「\(trimmedQuestion)」\n\n"
                : ""
            let user = """
            \(questionHeader)請用白話文解讀以下\(spreadLabel)，所有解讀都必須緊扣上面的問題：

            \(cardDescriptions)

            解讀方式：
            - 每張牌都要先說明它對這個問題的具體意義（口語化、正面鼓勵為主）
            - 若有需要注意的風險，誠實但溫和地提醒
            - 最後整合所有牌，給出一個針對這個問題的整體建議
            """
            return (system, user)

        case .single(let index):
            guard index < cards.count else { return (system, "") }
            let dc = cards[index]
            let meaning = dc.isReversed ? dc.card.reversed : dc.card.upright
            let questionHeader = hasQuestion
                ? "問卜者的問題：「\(trimmedQuestion)」\n\n"
                : ""
            let user = """
            \(questionHeader)請用白話文深度解讀這張牌，所有解讀都必須緊扣上面的問題：

            【\(dc.position)：\(dc.card.name)（\(dc.isReversed ? "逆位" : "正位")）】
            元素：\(dc.card.element)，關鍵詞：\(dc.card.keywords.joined(separator: "、"))
            牌義參考：\(meaning.general)

            請依序說明：
            1. 這張牌對這個問題說了什麼（白話一句話）
            2. 針對問題的正面啟示與機會
            3. 針對問題需要注意的風險（如果有）
            4. 在「\(dc.position)」這個位置，對這個問題代表什麼
            5. 針對問題，一個最重要的立即行動建議
            """
            return (system, user)
        }
    }

    // MARK: - Local generation (enhanced template engine)

    private func generateLocally(cards: [DrawnCard], mode: InterpretMode) -> String {
        switch mode {
        case .overall:
            if cards.count == 1 { return generateSingle(card: cards[0]) }
            return generateOverall(cards: cards)
        case .single(let index):
            guard index < cards.count else { return "" }
            return generateSingle(card: cards[index])
        }
    }

    private func generateOverall(cards: [DrawnCard]) -> String {
        guard cards.count >= 3 else { return LocalReadingService.interpretReading(cards) }

        let past    = cards[0]
        let present = cards[1]
        let future  = cards[2]

        let pastM    = past.isReversed    ? past.card.reversed    : past.card.upright
        let presentM = present.isReversed ? present.card.reversed : present.card.upright
        let futureM  = future.isReversed  ? future.card.reversed  : future.card.upright

        let analysis = SpreadAnalyzer.analyze(cards)

        let cardNames = cards.map(\.card.name).joined(separator: "、")
        let allKeywords = cards.flatMap(\.card.keywords)
            .uniqued().prefix(5).joined(separator: "、")

        return """
        ✦ 命運之鏡 · 三牌陣解讀 ✦

        \(cardNames)——
        三張牌在此刻交匯，以「\(allKeywords)」為靈魂的線索，
        為你編織一段獨特的命運敘事。

        ══════════════════════

        ◈ \(past.position)之牌 · \(past.card.name)（\(past.isReversed ? "逆位" : "正位")）
        元素：\(past.card.element)

        \(pastM.general)

        · 愛情　\(pastM.love)
        · 事業　\(pastM.career)
        · 財務　\(pastM.finance)
        · 靈性　\(pastM.spiritual)

        在「\(past.position)」的位置：
        \(past.card.positionMeaning.past)

        ══════════════════════

        ◈ \(present.position)之牌 · \(present.card.name)（\(present.isReversed ? "逆位" : "正位")）
        元素：\(present.card.element)

        \(presentM.general)

        · 愛情　\(presentM.love)
        · 事業　\(presentM.career)
        · 財務　\(presentM.finance)
        · 靈性　\(presentM.spiritual)

        在「\(present.position)」的位置：
        \(present.card.positionMeaning.present)

        ══════════════════════

        ◈ \(future.position)之牌 · \(future.card.name)（\(future.isReversed ? "逆位" : "正位")）
        元素：\(future.card.element)

        \(futureM.general)

        · 愛情　\(futureM.love)
        · 事業　\(futureM.career)
        · 財務　\(futureM.finance)
        · 靈性　\(futureM.spiritual)

        在「\(future.position)」的位置：
        \(future.card.positionMeaning.future)

        ══════════════════════

        ✦ 元素能量

        \(analysis.elementInsight)

        ✦ 主題模式

        \(analysis.themePattern)

        ✦ 能量流動

        \(analysis.energyFlow)

        ✦ 核心訊息

        \(analysis.coreMessage)

        ✦ 宇宙給你的建議

        \(analysis.advice)
        """ + extraCardSections(cards: cards)
    }

    private func extraCardSections(cards: [DrawnCard]) -> String {
        guard cards.count > 3 else { return "" }
        var text = ""
        for dc in cards.dropFirst(3) {
            let m = dc.isReversed ? dc.card.reversed : dc.card.upright
            text += """


        ══════════════════════

        ◈ \(dc.position)之牌 · \(dc.card.name)（\(dc.isReversed ? "逆位" : "正位")）
        元素：\(dc.card.element)

        \(m.general)

        · 愛情　\(m.love)
        · 事業　\(m.career)
        · 財務　\(m.finance)

        ✦ 建議：\(m.advice)
        """
        }
        return text
    }

    private func generateSingle(card: DrawnCard) -> String {
        let meaning = card.isReversed ? card.card.reversed : card.card.upright
        let orientation = card.isReversed ? "逆位" : "正位"

        let positionContext: String
        switch card.position {
        case "過去":                positionContext = card.card.positionMeaning.past
        case "現在", "今日指引",
             "自己", "情境", "建議": positionContext = card.card.positionMeaning.present
        default:                    positionContext = card.card.positionMeaning.future
        }

        let arcanaLabel = card.card.arcana == "major" ? "大阿爾克納" : "小阿爾克納"
        let reversedNote = card.isReversed
            ? "逆位提示這股能量正以更內斂的方式運作，邀請你審視尚未被意識到的內在阻力或被壓抑的潛力。"
            : "正位顯示此牌的能量正清晰而外顯地流動，是你此刻可以善用的核心資源。"

        return """
        ✦ \(card.position)之牌 · \(card.card.name)（\(orientation)）✦

        \(arcanaLabel) · 元素：\(card.card.element)
        關鍵詞：\(card.card.keywords.joined(separator: "、"))

        ══════════════════════

        ◈ 牌義核心

        \(meaning.general)

        ══════════════════════

        ◈ 愛情的訊息

        \(meaning.love)

        ◈ 事業的訊息

        \(meaning.career)

        ◈ 財務的訊息

        \(meaning.finance)

        ◈ 靈性的訊息

        \(meaning.spiritual)

        ══════════════════════

        ◈ 在「\(card.position)」位置的特別啟示

        \(positionContext)

        ══════════════════════

        ✦ 能量解讀

        \(reversedNote)

        ✦ 給你的行動建議

        \(meaning.advice)
        """
    }
}

// MARK: - Array helper

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

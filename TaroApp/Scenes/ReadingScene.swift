import SwiftUI

struct ReadingScene: View {
    let drawnCards: [DrawnCard]
    var userQuestion: String = ""
    var onReset: () -> Void

    @StateObject private var mlxService  = MLXReadingService.shared
    @ObservedObject private var download = ModelDownloadManager.shared

    @State private var selectedIndex: Int?  = nil
    @State private var zoomedIndex: Int?    = nil
    @State private var displayText          = ""
    @State private var streamTask: Task<Void, Never>? = nil
    @State private var showDownloadPrompt   = false
    @State private var showChat             = false

    private let gold = Color(hex: "#c9a84c")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Color(hex: "#0a0a0f").ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Cards row ──────────────────────────────────────────
                    let cardW = drawnCards.count <= 3 ? w * 0.28 : w * 0.16
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: drawnCards.count <= 3 ? 12 : 8) {
                            ForEach(0..<drawnCards.count, id: \.self) { i in
                                cardColumn(index: i, cardWidth: cardW)
                            }
                        }
                        .padding(.horizontal, drawnCards.count > 3 ? 12 : 16)
                    }
                    .padding(.top, 52)

                    // ── Divider ────────────────────────────────────────────
                    Rectangle()
                        .fill(gold.opacity(0.25))
                        .frame(height: 0.5)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                    // ── Download status banner ─────────────────────────────
                    downloadStatusBanner
                        .animation(.easeInOut(duration: 0.3), value: download.state)

                    // ── Interpretation text ────────────────────────────────
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Show user's question as context header
                            if !userQuestion.isEmpty {
                                HStack(spacing: 6) {
                                    Text("✦")
                                        .font(.system(size: 10))
                                        .foregroundColor(gold.opacity(0.5))
                                    Text(userQuestion)
                                        .font(.custom("Georgia", size: 13))
                                        .foregroundColor(gold.opacity(0.6))
                                        .italic()
                                        .lineLimit(2)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            }

                            if mlxService.isGenerating && displayText.isEmpty {
                                HStack {
                                    MysticLoadingView()
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 8)
                            }
                            Text(displayText)
                                .font(.custom("Georgia", size: 15))
                                .foregroundColor(Color(hex: "#e8d5a3"))
                                .lineSpacing(6)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // ── Bottom buttons ─────────────────────────────────────
                    VStack(spacing: 10) {
                        HStack(spacing: 16) {
                            ActionButton(title: "整體解讀", gold: gold) {
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                    zoomedIndex = nil
                                }
                                fetchOverallReading()
                            }
                            ActionButton(title: "再抽一次", gold: gold) {
                                streamTask?.cancel()
                                onReset()
                            }
                        }

                        // Chat button — only shown when AI model is ready
                        if mlxService.modelState == .ready && !displayText.isEmpty {
                            Button(action: { showChat = true }) {
                                HStack(spacing: 8) {
                                    Text("✦")
                                    Text("繼續追問解讀師")
                                        .tracking(1)
                                }
                                .font(.custom("Georgia", size: 14))
                                .foregroundColor(gold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(gold.opacity(0.08))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(gold.opacity(0.35), lineWidth: 0.5)
                                )
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                    .padding(.top, 12)
                    .sheet(isPresented: $showChat) {
                        NavigationStack {
                            ChatView(
                                container: mlxService.modelContainer,
                                readingContext: displayText,
                                userQuestion: userQuestion
                            )
                        }
                    }
                }

                // ── Zoomed card overlay ────────────────────────────────────
                if let zi = zoomedIndex {
                    let dc = drawnCards[zi]
                    Color.black.opacity(0.65)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                zoomedIndex = nil
                            }
                        }

                    let zoomW = w * 0.52
                    VStack(spacing: 12) {
                        TarotCardView(card: dc.card, isFlipped: true, isReversed: dc.isReversed)
                            .frame(width: zoomW)
                            .shadow(color: gold.opacity(0.35), radius: 24)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                                    zoomedIndex = nil
                                }
                            }

                        VStack(spacing: 4) {
                            Text(dc.card.name)
                                .font(.custom("Georgia", size: 18))
                                .foregroundColor(Color(hex: "#f0d080"))
                            HStack(spacing: 8) {
                                Text(dc.position)
                                    .font(.custom("Georgia", size: 13))
                                    .foregroundColor(gold.opacity(0.7))
                                    .tracking(2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .position(x: w / 2, y: h / 2)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }

                // ── Reading source badge（右上角固定位置）─────────────────
                if !displayText.isEmpty {
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 4) {
                                Text(mlxService.readingSource.icon)
                                Text(mlxService.readingSource.label)
                            }
                            .font(.system(size: 10))
                            .foregroundColor(
                                mlxService.readingSource == .onDeviceAI
                                    ? gold
                                    : gold.opacity(0.45)
                            )
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#0a0a0f").opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(
                                        mlxService.readingSource == .onDeviceAI
                                            ? gold.opacity(0.6)
                                            : gold.opacity(0.25),
                                        lineWidth: 0.5
                                    )
                            )
                            .cornerRadius(4)
                        }
                        .padding(.top, 56)
                        .padding(.trailing, 20)
                        Spacer()
                    }
                    .transition(.opacity)
                    .animation(.easeIn(duration: 0.4), value: displayText.isEmpty)
                }

                // ── First-time download prompt overlay ─────────────────────
                if showDownloadPrompt {
                    downloadPromptOverlay
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            fetchOverallReading()
            triggerBackgroundDownloadIfNeeded()
        }
        .onDisappear {
            streamTask?.cancel()
        }
    }

    // MARK: - Download status banner

    @ViewBuilder
    private var downloadStatusBanner: some View {
        switch download.state {
        case .downloading(let progress):
            VStack(spacing: 4) {
                HStack {
                    Text("✦ 正在召喚遠古智慧… \(Int(progress * 100))%")
                        .font(.custom("Georgia", size: 11))
                        .foregroundColor(gold.opacity(0.7))
                    Spacer()
                }
                .padding(.horizontal, 24)

                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(gold.opacity(0.12))
                        Rectangle()
                            .fill(gold.opacity(0.55))
                            .frame(width: g.size.width * progress)
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 8)

        case .failed(let msg):
            VStack(alignment: .leading, spacing: 4) {
                Text("✦ 召喚失敗")
                    .font(.custom("Georgia", size: 11))
                    .foregroundColor(.red.opacity(0.8))
                Text(msg)
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.6))
                    .lineLimit(4)
                Button("重試") { download.startDownload() }
                    .font(.system(size: 11))
                    .foregroundColor(gold)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

        case .notStarted, .completed:
            EmptyView()
        }
    }

    // MARK: - Download prompt overlay

    private var downloadPromptOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("✦ 深度 AI 解讀")
                    .font(.custom("Georgia", size: 20))
                    .foregroundColor(gold)
                    .tracking(3)

                Text("下載遠古智慧核心（約 1GB）\n一次下載，永久離線使用\n無需網路，無需訂閱費用")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(Color(hex: "#e8d5a3").opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                Text("建議在 Wi-Fi 環境下進行")
                    .font(.system(size: 11))
                    .foregroundColor(gold.opacity(0.5))

                HStack(spacing: 16) {
                    Button("稍後再說") {
                        withAnimation { showDownloadPrompt = false }
                    }
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(gold.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(gold.opacity(0.3), lineWidth: 1)
                    )

                    Button("開始召喚") {
                        withAnimation { showDownloadPrompt = false }
                        download.startDownload()
                    }
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(Color(hex: "#0a0a0f"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(gold)
                    .cornerRadius(8)
                }
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#12101e"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(gold.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Card column

    @ViewBuilder
    private func cardColumn(index i: Int, cardWidth: CGFloat) -> some View {
        let dc = drawnCards[i]
        VStack(spacing: 6) {
            TarotCardView(card: dc.card, isFlipped: true, isReversed: dc.isReversed)
                .frame(width: cardWidth)
                .overlay(
                    RoundedRectangle(cornerRadius: cardWidth * 0.06)
                        .strokeBorder(selectedIndex == i ? gold : Color.clear, lineWidth: 2)
                )
                .onTapGesture {
                    if zoomedIndex == i {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                            zoomedIndex = nil
                        }
                    } else {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                            zoomedIndex = i
                        }
                        fetchCardReading(index: i)
                    }
                }
                .scaleEffect(selectedIndex == i ? 1.04 : 1.0)
                .animation(.spring(response: 0.3), value: selectedIndex)

            Text(dc.position)
                .font(.custom("Georgia", size: 11))
                .foregroundColor(gold.opacity(0.7))
                .tracking(2)

            Text(dc.card.name)
                .font(.custom("Georgia", size: 12))
                .foregroundColor(Color(hex: "#e8d5a3").opacity(0.9))

        }
    }

    // MARK: - Fetch helpers

    private func fetchOverallReading() {
        selectedIndex = nil
        streamReading(mode: .overall)
    }

    private func fetchCardReading(index: Int) {
        selectedIndex = index
        streamReading(mode: .single(index))
    }

    private func streamReading(mode: MLXReadingService.InterpretMode) {
        streamTask?.cancel()
        displayText = ""

        streamTask = Task {
            let stream = mlxService.interpretStream(cards: drawnCards, mode: mode, question: userQuestion)
            for await chunk in stream {
                guard !Task.isCancelled else { break }
                displayText += chunk
            }
        }
    }

    // MARK: - Background download trigger

    private func triggerBackgroundDownloadIfNeeded() {
        let hasShown = UserDefaults.standard.bool(forKey: "hasShownAIDownloadPrompt")
        switch download.state {
        case .notStarted:
            if !hasShown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDownloadPrompt = true
                    }
                    UserDefaults.standard.set(true, forKey: "hasShownAIDownloadPrompt")
                }
            }
        default:
            break
        }
    }
}

// MARK: - Sub-views

private struct MysticLoadingView: View {
    @State private var rotation: Double = 0
    private let gold = Color(hex: "#c9a84c")

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(gold.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 28, height: 28)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(gold, lineWidth: 1.5)
                    .frame(width: 28, height: 28)
                    .rotationEffect(.degrees(rotation))
            }
            Text("靈光湧現中…")
                .font(.custom("Georgia", size: 13))
                .foregroundColor(gold.opacity(0.65))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

private struct ActionButton: View {
    let title: String
    let gold: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(gold)
                .tracking(2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(gold.opacity(0.6), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#1a1035").opacity(0.6))
                        )
                )
        }
    }
}

#Preview {
    let meaning = CardMeaning(general: "新的旅程正在召喚你。", love: "敞開心扉迎接新的可能。",
                              career: "勇敢踏出舒適圈。", finance: "謹慎理財，保持開放。",
                              spiritual: "靈魂渴望自由的探索。", advice: "相信直覺，踏出第一步。")
    let pos = PositionMeaning(past: "曾踏上的旅程塑造了你。", present: "此刻出發的勇氣。", future: "前方等待的無限可能。")
    let card = TarotCard(id: 0, name: "愚者", nameEn: "The Fool", arcana: "major", number: 0,
                         keywords: ["自由", "冒險", "新起點"], symbolKey: "fool", colorHex: "#FFD700",
                         element: "風", themes: ["新開始", "冒險"],
                         upright: meaning, reversed: meaning, positionMeaning: pos)
    let cards = [
        DrawnCard(card: card, isReversed: false, position: "過去"),
        DrawnCard(card: card, isReversed: true,  position: "現在"),
        DrawnCard(card: card, isReversed: false, position: "未來")
    ]
    ReadingScene(drawnCards: cards) { }
}

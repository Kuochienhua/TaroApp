import Foundation
import Combine
import MLXLMCommon

/// Maintains a live multi-turn conversation with the on-device model.
/// One instance per reading session — discard and recreate to reset context.
@MainActor
final class ConversationService: ObservableObject {

    struct Message: Identifiable {
        let id = UUID()
        let role: Role
        var text: String

        enum Role { case user, assistant }
    }

    @Published var messages: [Message] = []
    @Published var isThinking = false

    private var session: ChatSession?

    // MARK: - Setup

    /// Call once when the reading is ready.
    /// `userQuestion` is the original question the user asked before drawing cards.
    /// `readingContext` is the full reading text, used as background context.
    func beginSession(container: ModelContainer, readingContext: String, userQuestion: String = "") {
        let trimmedQuestion = userQuestion.trimmingCharacters(in: .whitespaces)
        let hasQuestion = !trimmedQuestion.isEmpty

        // Pin every reply to the original question so the chat never drifts off topic.
        let questionAnchor = hasQuestion
            ? """

            【核心任務——絕對不能離題】
            問卜者今天帶著一個明確問題來的：「\(trimmedQuestion)」
            對話中無論討論哪張牌、哪個面向，你的回答都必須扣回這個問題。
            - 每次回應都要和這個問題直接相關
            - 禁止給出與問題無關的泛論或一般性建議
            - 如果對方的追問偏題，溫和地把話題帶回這個問題
            """
            : ""

        let systemPrompt = """
        你是一位擁有二十年經驗的塔羅牌大師，正在與問卜者進行面對面的深度對話。
        你對每張牌的象徵瞭若指掌，但說話從不像在背書——你把牌義轉化成對方真正需要聽到的話。

        剛才完成的牌陣解讀如下，作為這段對話的背景：

        \(readingContext)\(questionAnchor)

        【對話方式】
        - 以繁體中文回應
        - 像老朋友一樣說話：自然、口語、有溫度，讓對方感到被理解
        - 把牌面訊息轉成有意義的生活語言，不說制式牌義
        - 直接切入重點，不說空話，每個回應都要和問卜者的問題或追問直接相關
        - 正面積極：從支持與希望的角度出發，讓對方感到有力量
        - 誠實貼心：若涉及風險，清楚但溫和地說，語氣是「提醒好友」而非「警告」
        - 每次回應控制在 120 字以內，保持對話的節奏感
        """

        session = ChatSession(
            container,
            instructions: systemPrompt,
            generateParameters: GenerateParameters(temperature: 0.75)
        )
    }

    // MARK: - Send message

    func send(_ userText: String) {
        guard let session, !userText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        messages.append(Message(role: .user, text: userText))

        // Placeholder for streaming reply
        let assistantIndex = messages.count
        messages.append(Message(role: .assistant, text: ""))
        isThinking = true

        Task {
            do {
                for try await chunk in session.streamResponse(to: userText) {
                    guard !Task.isCancelled else { break }
                    messages[assistantIndex].text += chunk
                }
            } catch {
                messages[assistantIndex].text = "（解讀師暫時無法回應，請稍後再試）"
            }
            isThinking = false
        }
    }
}

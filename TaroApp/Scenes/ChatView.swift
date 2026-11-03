import SwiftUI
import MLXLMCommon

struct ChatView: View {

    @StateObject private var conversation = ConversationService()
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    let container: ModelContainer?   // passed from ReadingScene
    let readingContext: String        // the full reading text as context
    let userQuestion: String          // original question, used to anchor every reply

    private let gold     = Color(hex: "#c9a84c")
    private let bgDeep   = Color(hex: "#0a0a0f")
    private let bgCard   = Color(hex: "#12101e")

    // Suggested follow-up questions
    private let suggestions = [
        "這張牌對我的感情有什麼建議？",
        "我應該如何面對目前的挑戰？",
        "未來三個月的重點是什麼？",
        "這個能量要如何轉化？",
        "有什麼行動是我現在可以做的？",
    ]

    var body: some View {
        ZStack {
            bgDeep.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                navBar

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if conversation.messages.isEmpty {
                                suggestionsView
                            }
                            ForEach(conversation.messages) { msg in
                                MessageBubble(message: msg, gold: gold, bgCard: bgCard)
                                    .id(msg.id)
                            }
                            if conversation.isThinking {
                                ThinkingIndicator(gold: gold)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: conversation.messages.count) {
                        if let last = conversation.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Input bar
                inputBar
            }
        }
        .onAppear {
            if let container {
                conversation.beginSession(
                    container: container,
                    readingContext: readingContext,
                    userQuestion: userQuestion
                )
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Sub-views

    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(gold)
            }
            Spacer()
            Text("✦ 深度追問")
                .font(.custom("Georgia", size: 15))
                .foregroundColor(gold)
                .tracking(2)
            Spacer()
            // Balance spacing
            Image(systemName: "chevron.left").opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(bgDeep)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(gold.opacity(0.2)),
            alignment: .bottom
        )
    }

    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("你可以繼續問：")
                .font(.custom("Georgia", size: 12))
                .foregroundColor(gold.opacity(0.5))
                .padding(.top, 8)

            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: { sendMessage(suggestion) }) {
                    Text(suggestion)
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(gold.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(gold.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(gold.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("", text: $inputText, prompt:
                Text("繼續追問…").foregroundColor(gold.opacity(0.3))
            )
            .font(.custom("Georgia", size: 14))
            .foregroundColor(.white)
            .focused($inputFocused)
            .submitLabel(.send)
            .onSubmit { sendMessage(inputText) }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(bgCard)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(gold.opacity(0.25), lineWidth: 0.5)
            )

            Button(action: { sendMessage(inputText) }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(inputText.isEmpty ? gold.opacity(0.2) : gold)
            }
            .disabled(inputText.isEmpty || conversation.isThinking)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(bgDeep)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(gold.opacity(0.2)),
            alignment: .top
        )
    }

    private func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        inputText = ""
        conversation.send(trimmed)
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: ConversationService.Message
    let gold: Color
    let bgCard: Color

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .assistant {
                    Text("✦ 解讀師")
                        .font(.system(size: 10))
                        .foregroundColor(gold.opacity(0.5))
                }
                Text(message.text.isEmpty ? "…" : message.text)
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(message.role == .user ? .white : Color(hex: "#e8d5a3"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? gold.opacity(0.15)
                            : bgCard
                    )
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(gold.opacity(0.15), lineWidth: 0.5)
                    )
            }

            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}

// MARK: - ThinkingIndicator

private struct ThinkingIndicator: View {
    let gold: Color
    @State private var opacity = 0.3

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(gold)
                    .frame(width: 6, height: 6)
                    .opacity(opacity)
                    .animation(
                        .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2),
                        value: opacity
                    )
            }
        }
        .padding(.leading, 14)
        .onAppear { opacity = 1.0 }
    }
}

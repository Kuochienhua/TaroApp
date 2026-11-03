import SwiftUI

struct QuestionScene: View {

    @Binding var question: String
    @Binding var selectedSpread: SpreadType
    var onContinue: () -> Void

    @FocusState private var focused: Bool
    @State private var visible       = false
    @State private var selectedTopic: Topic? = nil

    private let gold   = Color(hex: "#c9a84c")
    private let bgDeep = Color(hex: "#0a0a0f")
    private let bgCard = Color(hex: "#12101e")

    private var canContinue: Bool {
        question.trimmingCharacters(in: .whitespaces).count >= 5
    }

    var body: some View {
        ZStack {
            bgDeep.ignoresSafeArea()
            ParticleView(style: .smoke, count: 30).ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    titleSection
                        .padding(.top, 60)

                    topicSection
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    if let topic = selectedTopic {
                        suggestionsRow(topic: topic)
                            .padding(.top, 12)
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    questionInputSection
                        .padding(.top, 16)
                        .padding(.horizontal, 24)

                    spreadPickerSection
                        .padding(.top, 22)
                        .padding(.horizontal, 24)

                    continueButton
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    skipButton
                        .padding(.top, 14)

                    Spacer().frame(height: 60)
                }
            }
        }
        .onTapGesture { focused = false }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.3)) { visible = true }
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 10) {
            Text("✦")
                .font(.system(size: 24))
                .foregroundColor(gold)
            Text("在抽牌之前")
                .font(.custom("Cinzel Decorative", size: 20))
                .foregroundColor(gold)
                .tracking(4)
            Text("請將心中的疑問，化為文字")
                .font(.custom("Georgia", size: 13))
                .foregroundColor(gold.opacity(0.6))
                .tracking(2)
        }
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 20)
    }

    // MARK: - Topic selector

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("情境主題")
                .font(.custom("Georgia", size: 11))
                .foregroundColor(gold.opacity(0.45))
                .tracking(3)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Topic.allCases, id: \.self) { topic in
                    topicChip(topic)
                }
            }
        }
        .opacity(visible ? 1 : 0)
    }

    private func topicChip(_ topic: Topic) -> some View {
        let isSelected = selectedTopic == topic
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTopic = isSelected ? nil : topic
            }
            if !isSelected && question.isEmpty {
                question = ""
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            VStack(spacing: 3) {
                Text(topic.icon)
                    .font(.system(size: 16))
                Text(topic.name)
                    .font(.custom("Georgia", size: 11))
                    .foregroundColor(isSelected ? gold : gold.opacity(0.6))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? gold.opacity(0.12) : Color.clear)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? gold.opacity(0.7) : gold.opacity(0.2), lineWidth: isSelected ? 1 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Suggestions

    private func suggestionsRow(topic: Topic) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("建議問題")
                .font(.custom("Georgia", size: 11))
                .foregroundColor(gold.opacity(0.4))
                .tracking(3)

            ForEach(topic.suggestions, id: \.self) { suggestion in
                Button(action: {
                    question = suggestion
                    focused = false
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Text("›")
                            .font(.system(size: 14))
                            .foregroundColor(gold.opacity(0.5))
                        Text(suggestion)
                            .font(.custom("Georgia", size: 12))
                            .foregroundColor(gold.opacity(0.8))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(gold.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(gold.opacity(0.15), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Question input

    private var questionInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("你的問題")
                .font(.custom("Georgia", size: 11))
                .foregroundColor(gold.opacity(0.45))
                .tracking(3)

            ZStack(alignment: .topLeading) {
                if question.isEmpty {
                    Text("例如：我的感情走向如何？")
                        .font(.custom("Georgia", size: 14))
                        .foregroundColor(gold.opacity(0.22))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $question)
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(Color(hex: "#e8d5a3"))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .focused($focused)
                    .frame(height: 90)
            }
            .background(bgCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        focused ? gold.opacity(0.6) : gold.opacity(0.2),
                        lineWidth: focused ? 1 : 0.5
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focused)
        }
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 12)
    }

    // MARK: - Spread picker

    private var spreadPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選擇牌陣")
                .font(.custom("Georgia", size: 11))
                .foregroundColor(gold.opacity(0.45))
                .tracking(3)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(SpreadType.allCases) { spread in
                    spreadCard(spread)
                }
            }
        }
        .opacity(visible ? 1 : 0)
    }

    private func spreadCard(_ spread: SpreadType) -> some View {
        let isSelected = selectedSpread == spread
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSpread = spread
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            VStack(alignment: .leading, spacing: 6) {
                Text(spread.cardDots)
                    .font(.system(size: isSelected ? 13 : 11))
                    .foregroundColor(isSelected ? gold : gold.opacity(0.5))
                    .tracking(3)

                Text(spread.displayName)
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(isSelected ? gold : gold.opacity(0.7))
                    .fontWeight(isSelected ? .semibold : .regular)

                Text(spread.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? gold.opacity(0.7) : gold.opacity(0.35))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? gold.opacity(0.1) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? gold.opacity(0.7) : gold.opacity(0.2), lineWidth: isSelected ? 1 : 0.5)
            )
            .shadow(color: isSelected ? gold.opacity(0.2) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    // MARK: - Continue button

    private var continueButton: some View {
        Button(action: {
            focused = false
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            onContinue()
        }) {
            Text("✦  召喚牌陣  ✦")
                .font(.custom("Georgia", size: 16))
                .tracking(4)
                .foregroundColor(canContinue ? gold : gold.opacity(0.3))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            canContinue ? gold.opacity(0.8) : gold.opacity(0.2),
                            lineWidth: 1
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(canContinue ? gold.opacity(0.08) : Color.clear)
                        )
                )
                .shadow(color: canContinue ? gold.opacity(0.3) : .clear, radius: 10)
        }
        .disabled(!canContinue)
        .opacity(visible ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: canContinue)
    }

    // MARK: - Skip button

    private var skipButton: some View {
        Button(action: {
            question = ""
            focused = false
            onContinue()
        }) {
            Text("略過，直接抽牌")
                .font(.custom("Georgia", size: 12))
                .foregroundColor(gold.opacity(0.3))
        }
        .opacity(visible ? 1 : 0)
    }
}

// MARK: - Topic

extension QuestionScene {
    enum Topic: CaseIterable, Hashable {
        case love, career, finance, health, spiritual, free

        var name: String {
            switch self {
            case .love:      return "感情"
            case .career:    return "事業"
            case .finance:   return "財運"
            case .health:    return "健康"
            case .spiritual: return "靈性"
            case .free:      return "自由"
            }
        }

        var icon: String {
            switch self {
            case .love:      return "❤️"
            case .career:    return "⭐️"
            case .finance:   return "🌙"
            case .health:    return "🌿"
            case .spiritual: return "✨"
            case .free:      return "🔮"
            }
        }

        var suggestions: [String] {
            switch self {
            case .love:
                return [
                    "我的感情走向會如何發展？",
                    "這段關係值得繼續投入嗎？",
                    "我如何才能找到真愛？",
                ]
            case .career:
                return [
                    "我現在的工作方向對嗎？",
                    "這次轉職或升遷的機會如何？",
                    "我的職涯瓶頸如何突破？",
                ]
            case .finance:
                return [
                    "我近期的財運走勢如何？",
                    "這項投資或計畫值得嗎？",
                    "如何改善我目前的財務狀況？",
                ]
            case .health:
                return [
                    "我的身心需要哪方面的關注？",
                    "如何讓我的狀態更加平衡？",
                    "我的健康接下來有什麼需要留意？",
                ]
            case .spiritual:
                return [
                    "我現在靈魂的課題是什麼？",
                    "我正走在對的靈性道路上嗎？",
                    "宇宙此刻想對我傳達什麼訊息？",
                ]
            case .free:
                return [
                    "我在人生轉捩點，需要指引",
                    "關於當前的困惑，宇宙有何建議？",
                    "此刻我最需要聽到什麼？",
                ]
            }
        }
    }
}

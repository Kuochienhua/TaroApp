import SwiftUI

struct DrawScene: View {
    let drawnCards: [DrawnCard]
    var onComplete: () -> Void

    @State private var offsets:   [CGSize]
    @State private var rotations: [Double]
    @State private var flipped:   [Bool]
    @State private var deckShake: CGFloat = 0
    @State private var viewSize: CGSize = .zero

    private let gold = Color(hex: "#c9a84c")

    init(drawnCards: [DrawnCard], onComplete: @escaping () -> Void) {
        self.drawnCards = drawnCards
        self.onComplete = onComplete
        let n = drawnCards.count
        self._offsets   = State(initialValue: Array(repeating: .zero, count: n))
        self._rotations = State(initialValue: Array(repeating: 0.0,   count: n))
        self._flipped   = State(initialValue: Array(repeating: false, count: n))
    }

    private var cardWidth: CGFloat {
        drawnCards.count <= 3 ? 90 : 65
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Color.clear
                    .onAppear { viewSize = geo.size }

                Color(hex: "#0a0a0f").ignoresSafeArea()

                CardDeckSource()
                    .frame(width: 80, height: 112)
                    .position(x: w / 2, y: h * 0.38)
                    .offset(x: deckShake)

                ForEach(0..<drawnCards.count, id: \.self) { i in
                    let dc = drawnCards[i]
                    TarotCardView(card: dc.card, isFlipped: flipped[i], isReversed: dc.isReversed)
                        .frame(width: cardWidth)
                        .position(x: w / 2, y: h * 0.38)
                        .offset(offsets[i])
                        .rotationEffect(.degrees(rotations[i]))
                }

                if flipped.allSatisfy({ $0 }) {
                    let labelWidth = w / CGFloat(drawnCards.count)
                    HStack(spacing: 0) {
                        ForEach(0..<drawnCards.count, id: \.self) { i in
                            Text(drawnCards[i].position)
                                .font(.custom("Georgia", size: 12))
                                .foregroundColor(gold.opacity(0.8))
                                .tracking(2)
                                .frame(width: labelWidth)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .position(x: w / 2, y: h * 0.75)
                    .transition(.opacity)
                }
            }
        }
        .onChange(of: viewSize) { _, size in
            guard size != .zero else { return }
            runAnimation(width: size.width, height: size.height)
        }
    }

    // MARK: - Target positions

    private func targetOffsets(width w: CGFloat, height h: CGFloat) -> [CGSize] {
        let yOffset = h * 0.14
        let count = drawnCards.count
        switch count {
        case 1:
            return [CGSize(width: 0, height: yOffset)]
        case 3:
            return [
                CGSize(width: -w * 0.3, height: yOffset),
                CGSize(width:  0,       height: yOffset),
                CGSize(width:  w * 0.3, height: yOffset)
            ]
        case 5:
            let step = w * 0.22
            return (-2...2).map { CGSize(width: CGFloat($0) * step, height: yOffset) }
        default:
            let span = w * 0.7
            let step = count > 1 ? span / CGFloat(count - 1) : 0
            return (0..<count).map { i in
                CGSize(width: -span / 2 + step * CGFloat(i), height: yOffset)
            }
        }
    }

    // MARK: - Animation sequence

    private func runAnimation(width w: CGFloat, height h: CGFloat) {
        let count = drawnCards.count
        let targets = targetOffsets(width: w, height: h)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        withAnimation(.easeInOut(duration: 0.08).repeatCount(6, autoreverses: true)) {
            deckShake = 6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impact.impactOccurred()
        }

        for i in 0..<count {
            let delay = Double(i) * 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.4)) { rotations[i] = 360 }
                withAnimation(.easeOut(duration: 0.8)) { offsets[i] = targets[i] }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.2)) { rotations[i] = 0 }
                }
            }
        }

        let flipStart = Double(count - 1) * 0.3 + 0.8 + 0.3
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + flipStart + Double(i) * 0.3) {
                withAnimation(.easeInOut(duration: 0.7)) { flipped[i] = true }
            }
        }

        let totalDuration = flipStart + Double(count) * 0.3 + 0.7 + 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            onComplete()
        }
    }
}

// MARK: - Deck source

private struct CardDeckSource: View {
    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                CardBackView()
                    .offset(x: CGFloat(i) * 0.5, y: CGFloat(-i) * 1.0)
                    .rotationEffect(.degrees(Double(i - 3) * 0.6))
            }
        }
    }
}

#Preview {
    let m = CardMeaning(general: "", love: "", career: "", finance: "", spiritual: "", advice: "")
    let p = PositionMeaning(past: "", present: "", future: "")
    let sample = TarotCard(id: 0, name: "愚者", nameEn: "The Fool", arcana: "major", number: 0,
                           keywords: [], symbolKey: "fool", colorHex: "#FFD700",
                           element: "風", themes: ["新開始"],
                           upright: m, reversed: m, positionMeaning: p)
    let cards = [
        DrawnCard(card: sample, isReversed: false, position: "過去"),
        DrawnCard(card: sample, isReversed: true,  position: "現在"),
        DrawnCard(card: sample, isReversed: false, position: "未來")
    ]
    DrawScene(drawnCards: cards) { }
}

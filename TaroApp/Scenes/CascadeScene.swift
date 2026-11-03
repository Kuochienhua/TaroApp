import SwiftUI

struct CascadeScene: View {
    var onComplete: () -> Void

    /// Number of cards to show (22 Major Arcana)
    private let cardCount = 22
    private let cardWidth: CGFloat = 52

    @State private var positions: [CGSize] = []
    @State private var rotations: [Double] = []
    @State private var appeared: [Bool] = []

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Color(hex: "#0a0a0f").ignoresSafeArea()

                // Fan of cards
                ForEach(0..<cardCount, id: \.self) { i in
                    CardBackView()
                        .frame(width: cardWidth, height: cardWidth / TarotCardView.aspectRatio)
                        .rotationEffect(.degrees(appeared[safe: i] == true ? rotations[safe: i] ?? 0 : 0))
                        .offset(appeared[safe: i] == true ? positions[safe: i] ?? CGSize(width: w/2, height: -200)
                                                          : CGSize(width: w/2, height: -220))
                        .opacity(appeared[safe: i] == true ? 1 : 0)
                        .shadow(color: Color(hex: "#c9a84c").opacity(0.2), radius: 4)
                }
            }
            .onAppear {
                setupPositions(geo: geo)
                animateCards(totalWidth: w, totalHeight: h)
            }
        }
    }

    private func setupPositions(geo: GeometryProxy) {
        let w = geo.size.width
        let h = geo.size.height
        positions = fanPositions(count: cardCount, canvasWidth: w, canvasHeight: h)
        rotations = fanRotations(count: cardCount)
        appeared = Array(repeating: false, count: cardCount)
    }

    private func animateCards(totalWidth: CGFloat, totalHeight: CGFloat) {
        for i in 0..<cardCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    if i < appeared.count { appeared[i] = true }
                }
            }
        }
        // All cards appeared + 1s pause → advance
        let totalDelay = Double(cardCount) * 0.08 + 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            onComplete()
        }
    }

    // MARK: Fan layout helpers

    private func fanPositions(count: Int, canvasWidth: CGFloat, canvasHeight: CGFloat) -> [CGSize] {
        let cx = canvasWidth / 2
        let cy = canvasHeight * 0.52
        let spreadAngle: Double = 140   // total spread in degrees
        let radius: Double = Double(canvasWidth) * 0.42

        return (0..<count).map { i in
            let t = Double(i) / Double(count - 1)
            let angle = (t * spreadAngle - spreadAngle / 2) * .pi / 180
            let x = cx + CGFloat(cos(angle - .pi/2) * radius * 0.6)
            let y = cy + CGFloat(sin(angle - .pi/2) * radius * 0.3)
            return CGSize(width: x - canvasWidth/2, height: y - canvasHeight/2)
        }
    }

    private func fanRotations(count: Int) -> [Double] {
        let spread: Double = 130
        return (0..<count).map { i in
            let t = Double(i) / Double(count - 1)
            return t * spread - spread / 2
        }
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    CascadeScene { }
}

import SwiftUI

struct TableScene: View {
    var onComplete: () -> Void

    private let cardCount = 22
    private let cardWidth: CGFloat = 48

    @State private var landed: [Bool] = []

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Velvet table background
                VelvetTableBackground()
                    .ignoresSafeArea()

                // Cards in a horizontal row
                let spacing = max(2, (w - CGFloat(cardCount) * cardWidth) / CGFloat(cardCount + 1))
                HStack(spacing: spacing) {
                    ForEach(0..<cardCount, id: \.self) { i in
                        CardRowItem(
                            cardWidth: cardWidth,
                            isLanded: i < landed.count ? landed[i] : false,
                            fallHeight: h * 0.7,
                            delay: Double(i) * 0.04
                        )
                    }
                }
                .padding(.horizontal, 6)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .onAppear {
                landed = Array(repeating: false, count: cardCount)
                // Trigger landing animation on next run loop tick
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    landed = Array(repeating: true, count: cardCount)
                }
                // Advance after all cards land + pause
                let delay = Double(cardCount) * 0.04 + 1.5
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Single card row item

private struct CardRowItem: View {
    let cardWidth: CGFloat
    let isLanded: Bool
    let fallHeight: CGFloat
    let delay: Double

    var body: some View {
        let cardHeight = cardWidth / TarotCardView.aspectRatio
        let yOffset: CGFloat = isLanded ? 0 : -fallHeight
        let opacity: Double = isLanded ? 1 : 0
        let anim = Animation.spring(response: 0.45, dampingFraction: 0.55).delay(delay)

        CardBackView()
            .frame(width: cardWidth, height: cardHeight)
            .rotationEffect(.degrees(Double.random(in: -4...4)))
            .offset(y: yOffset)
            .opacity(opacity)
            .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
            .animation(anim, value: isLanded)
    }
}

// MARK: - Velvet table background

private struct VelvetTableBackground: View {
    var body: some View {
        Canvas { ctx, size in
            // Base gradient
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "#0d2b0d"), Color(hex: "#1a4a1a"), Color(hex: "#0d2b0d")]),
                    startPoint: CGPoint(x: size.width/2, y: 0),
                    endPoint: CGPoint(x: size.width/2, y: size.height)
                )
            )
            // Radial highlight
            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .radialGradient(
                    Gradient(colors: [Color(hex: "#2a6a2a").opacity(0.4), .clear]),
                    center: CGPoint(x: size.width/2, y: size.height/2),
                    startRadius: 0,
                    endRadius: size.width * 0.7
                )
            )
            // Noise texture (fine dots)
            for _ in 0..<3000 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let s = CGFloat.random(in: 0.3...1.2)
                let a = Double.random(in: 0.01...0.06)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: s, height: s)),
                    with: .color(.black.opacity(a))
                )
            }
        }
    }
}

#Preview {
    TableScene { }
}

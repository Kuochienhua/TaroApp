import SwiftUI

struct MysticScene: View {
    var onDraw: () -> Void

    @State private var textVisible = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonGlow: CGFloat = 0.4

    private let gold = Color(hex: "#c9a84c")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ── Background ──────────────────────────────────────────────
                Color(hex: "#0a0a0f").ignoresSafeArea()

                // ── Smoke particles ─────────────────────────────────────────
                ParticleView(style: .smoke, count: 45)
                    .ignoresSafeArea()

                // ── Candle glows (corner orange halos) ──────────────────────
                CandleGlow(x: w * 0.08, y: h * 0.78)
                CandleGlow(x: w * 0.92, y: h * 0.82)

                // ── Silhouette figure ────────────────────────────────────────
                SilhouetteView()
                    .frame(width: w * 0.65, height: h * 0.72)
                    .position(x: w / 2, y: h * 0.35)

                // ── Card stack in hands ──────────────────────────────────────
                CardDeckStack()
                    .frame(width: 80, height: 112)
                    .position(x: w / 2, y: h * 0.58)
                    .shadow(color: gold.opacity(0.3), radius: 10)

                // ── Text + button ─────────────────────────────────────────────
                VStack(spacing: 20) {
                    Spacer()

                    Text("命運之牌，為你展開")
                        .font(.custom("Georgia", size: 20))
                        .foregroundColor(gold)
                        .tracking(3)
                        .opacity(textVisible ? 1 : 0)

                    // Draw button
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        onDraw()
                    }) {
                        Text("✦  抽  牌  ✦")
                            .font(.custom("Georgia", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(gold)
                            .tracking(6)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(gold, lineWidth: 1.5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "#1a1035").opacity(0.8))
                                    )
                            )
                            .shadow(color: gold.opacity(buttonGlow), radius: 14)
                    }
                    .scaleEffect(buttonScale)
                    .opacity(textVisible ? 1 : 0)

                    Spacer().frame(height: h * 0.08)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.8)) { textVisible = true }
            }
            // Pulsing button
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                buttonScale = 1.05
                buttonGlow = 0.8
            }
        }
    }
}

// MARK: - Candle glow

private struct CandleGlow: View {
    let x: CGFloat
    let y: CGFloat
    @State private var flickerOpacity: CGFloat = 0.25

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(red: 1, green: 0.65, blue: 0.2).opacity(flickerOpacity), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 50
                )
            )
            .frame(width: 100, height: 100)
            .position(x: x, y: y)
            .onAppear {
                withAnimation(.easeInOut(duration: Double.random(in: 0.8...1.6)).repeatForever(autoreverses: true)) {
                    flickerOpacity = Double.random(in: 0.15...0.45)
                }
            }
        .allowsHitTesting(false)
    }
}

// MARK: - Stacked card deck

private struct CardDeckStack: View {
    var body: some View {
        ZStack {
            ForEach(0..<5) { i in
                CardBackView()
                    .offset(x: CGFloat(i) * 0.6, y: CGFloat(-i) * 1.2)
                    .rotationEffect(.degrees(Double(i - 2) * 0.8))
            }
        }
    }
}

#Preview {
    MysticScene { }
}

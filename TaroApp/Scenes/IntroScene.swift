import SwiftUI

struct IntroScene: View {
    var onComplete: () -> Void

    @State private var titleVisible = false
    @State private var titleBlur: CGFloat = 30
    @State private var subtitleText = ""
    @State private var shimmerOffset: CGFloat = -200

    private let subtitle = "命運，由此展開"
    private let gold = Color(hex: "#c9a84c")

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#0a0a0f").ignoresSafeArea()

            // Gold stardust particles
            ParticleView(style: .stardust, count: 70)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // ── TAROT title ──────────────────────────────────────────────
                ZStack {
                    Text("TAROT")
                        .font(.custom("Georgia", size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(gold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .blur(radius: titleBlur)
                        .opacity(titleVisible ? 1 : 0)

                    // Shimmer overlay
                    if titleVisible {
                        Text("TAROT")
                            .font(.custom("Georgia", size: 48))
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.clear, Color(hex: "#f0d080").opacity(0.6), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .mask(
                                Text("TAROT")
                                    .font(.custom("Georgia", size: 48))
                                    .fontWeight(.bold)
                            )
                            .offset(x: shimmerOffset)
                    }
                }

                // ── Divider line ─────────────────────────────────────────────
                Rectangle()
                    .fill(gold.opacity(0.4))
                    .frame(height: 0.5)
                    .padding(.horizontal, 60)
                    .opacity(titleVisible ? 1 : 0)

                // ── Typewriter subtitle ──────────────────────────────────────
                Text(subtitleText)
                    .font(.custom("Georgia", size: 18))
                    .foregroundColor(gold.opacity(0.85))
                    .tracking(4)

                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startSequence()
        }
    }

    private func startSequence() {
        // Phase 1: title fades in (0.0 → 1.5s)
        withAnimation(.easeOut(duration: 1.5)) {
            titleVisible = true
            titleBlur = 0
        }

        // Phase 2: shimmer sweep (1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.linear(duration: 1.0)) {
                shimmerOffset = 300
            }
        }

        // Phase 3: typewriter (2.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            typewriterAnimate()
        }

        // Phase 4: auto-advance (4.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            onComplete()
        }
    }

    private func typewriterAnimate() {
        var index = subtitle.startIndex
        func appendNext() {
            guard index < subtitle.endIndex else { return }
            subtitleText.append(subtitle[index])
            index = subtitle.index(after: index)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appendNext()
            }
        }
        appendNext()
    }
}

#Preview {
    IntroScene { }
}

import SwiftUI

/// A pair of white-gloved hands floating upward, palms facing up.
struct MysticHandsView: View {
    @State private var floatOffset: CGFloat = 0
    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let mid = w / 2

            ZStack {
                // Left hand
                HandShape(mirrored: false)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#ffffff"), Color(hex: "#e8e8f0")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        HandShape(mirrored: false)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color(hex: "#f0d080").opacity(0.25), .clear],
                                    startPoint: UnitPoint(x: shimmerPhase, y: 0),
                                    endPoint: UnitPoint(x: shimmerPhase + 0.4, y: 1)
                                )
                            )
                    )
                    .frame(width: w * 0.38, height: geo.size.height)
                    .position(x: mid - w * 0.18, y: geo.size.height / 2)
                    .offset(y: floatOffset)
                    .shadow(color: Color(hex: "#c9a84c").opacity(0.3), radius: 12)

                // Right hand (mirrored)
                HandShape(mirrored: true)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#e8e8f0"), Color(hex: "#ffffff")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        HandShape(mirrored: true)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color(hex: "#f0d080").opacity(0.25), .clear],
                                    startPoint: UnitPoint(x: shimmerPhase, y: 0),
                                    endPoint: UnitPoint(x: shimmerPhase + 0.4, y: 1)
                                )
                            )
                    )
                    .frame(width: w * 0.38, height: geo.size.height)
                    .position(x: mid + w * 0.18, y: geo.size.height / 2)
                    .offset(y: floatOffset + 8)    // slight phase offset
                    .shadow(color: Color(hex: "#c9a84c").opacity(0.3), radius: 12)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                floatOffset = -16
            }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                shimmerPhase = 1.0
            }
        }
    }
}

// MARK: - Hand shape

private struct HandShape: Shape {
    var mirrored: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let cx = mirrored ? w : 0

        // Palm base
        p.move(to:    CGPoint(x: cx + dir*w*0.1,  y: h*0.55))
        p.addLine(to: CGPoint(x: cx + dir*w*0.85, y: h*0.55))
        p.addCurve(to: CGPoint(x: cx + dir*w*0.9,  y: h*0.82),
                   control1: CGPoint(x: cx + dir*w*0.92, y: h*0.6),
                   control2: CGPoint(x: cx + dir*w*0.92, y: h*0.76))
        p.addLine(to: CGPoint(x: cx + dir*w*0.1,  y: h*0.82))
        p.addCurve(to: CGPoint(x: cx + dir*w*0.1, y: h*0.55),
                   control1: CGPoint(x: cx + dir*w*0.06, y: h*0.78),
                   control2: CGPoint(x: cx + dir*w*0.06, y: h*0.6))

        // Fingers (4 fingers + thumb)
        let fingerBases: [CGFloat] = [0.72, 0.58, 0.44, 0.30]
        let fingerTops:  [CGFloat] = [0.08, 0.04, 0.06, 0.12]
        let fingerWidths: [CGFloat] = [0.1, 0.1, 0.1, 0.1]

        for (i, baseX) in fingerBases.enumerated() {
            let bx = cx + dir * w * baseX
            let fw = w * fingerWidths[i]
            p.move(to:    CGPoint(x: bx - fw/2, y: h*0.56))
            p.addLine(to: CGPoint(x: bx - fw/2, y: h * fingerTops[i]))
            p.addCurve(to: CGPoint(x: bx + fw/2, y: h * fingerTops[i]),
                       control1: CGPoint(x: bx - fw/2, y: h * (fingerTops[i] - 0.04)),
                       control2: CGPoint(x: bx + fw/2, y: h * (fingerTops[i] - 0.04)))
            p.addLine(to: CGPoint(x: bx + fw/2, y: h*0.56))
        }

        // Thumb
        let thumbX = cx + dir * w * 0.84
        p.move(to:    CGPoint(x: thumbX, y: h*0.62))
        p.addCurve(to: CGPoint(x: thumbX + dir*w*0.1, y: h*0.38),
                   control1: CGPoint(x: thumbX + dir*w*0.14, y: h*0.58),
                   control2: CGPoint(x: thumbX + dir*w*0.16, y: h*0.44))
        p.addCurve(to: CGPoint(x: thumbX, y: h*0.5),
                   control1: CGPoint(x: thumbX + dir*w*0.08, y: h*0.32),
                   control2: CGPoint(x: thumbX - dir*w*0.04, y: h*0.46))

        return p
    }

    private var dir: CGFloat { mirrored ? -1 : 1 }
}

#Preview {
    MysticHandsView()
        .frame(width: 280, height: 180)
        .background(Color(hex: "#0a0a0f"))
}

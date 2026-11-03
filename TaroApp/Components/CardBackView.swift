import SwiftUI

/// The unified card back — deep purple with gold octagram and geometric border.
struct CardBackView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: w * 0.06)
                    .fill(Color(hex: "#1a1035"))

                Canvas { ctx, size in
                    let w = size.width
                    let h = size.height
                    let cx = w / 2
                    let cy = h / 2
                    let gold = Color(hex: "#c9a84c")

                    // ── Double border ──────────────────────────────────────────
                    let outerInset: CGFloat = w * 0.05
                    let innerInset: CGFloat = w * 0.09
                    let radius = w * 0.055

                    func borderRect(_ inset: CGFloat) -> Path {
                        RoundedRectangle(cornerRadius: radius)
                            .path(in: CGRect(
                                x: inset, y: inset,
                                width: w - inset * 2, height: h - inset * 2
                            ))
                    }

                    ctx.stroke(borderRect(outerInset), with: .color(gold), lineWidth: 1.2)
                    ctx.stroke(borderRect(innerInset), with: .color(gold.opacity(0.6)), lineWidth: 0.7)

                    // ── Corner stars ─────────────────────────────────────────
                    let cornerOffset: CGFloat = w * 0.14
                    let starCorners: [(CGFloat, CGFloat)] = [
                        (cornerOffset, cornerOffset),
                        (w - cornerOffset, cornerOffset),
                        (cornerOffset, h - cornerOffset),
                        (w - cornerOffset, h - cornerOffset)
                    ]
                    for (sx, sy) in starCorners {
                        ctx.fill(starPath(cx: sx, cy: sy, outerR: w * 0.045, innerR: w * 0.02, points: 4),
                                 with: .color(gold.opacity(0.7)))
                    }

                    // ── Central octagram ─────────────────────────────────────
                    let outerR = w * 0.28
                    let innerR = outerR * 0.42
                    ctx.fill(starPath(cx: cx, cy: cy, outerR: outerR, innerR: innerR, points: 8),
                             with: .color(gold.opacity(0.18)))
                    ctx.stroke(starPath(cx: cx, cy: cy, outerR: outerR, innerR: innerR, points: 8),
                                with: .color(gold), lineWidth: 1.0)

                    // ── Inner circle ─────────────────────────────────────────
                    let circR = innerR * 1.1
                    ctx.stroke(
                        Circle().path(in: CGRect(x: cx - circR, y: cy - circR,
                                                 width: circR * 2, height: circR * 2)),
                        with: .color(gold.opacity(0.5)), lineWidth: 0.8
                    )
                }

                RoundedRectangle(cornerRadius: w * 0.06)
                    .strokeBorder(Color(hex: "#c9a84c").opacity(0.3), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - Star path helper (shared)

func starPath(cx: CGFloat, cy: CGFloat,
              outerR: CGFloat, innerR: CGFloat, points: Int) -> Path {
    var path = Path()
    let total = points * 2
    for i in 0..<total {
        let angle = (CGFloat(i) / CGFloat(total)) * .pi * 2 - .pi / 2
        let r = i.isMultiple(of: 2) ? outerR : innerR
        let x = cx + r * cos(angle)
        let y = cy + r * sin(angle)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
        else        { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

#Preview {
    CardBackView()
        .frame(width: 160, height: 224)
        .padding()
        .background(Color.black)
}

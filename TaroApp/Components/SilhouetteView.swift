import SwiftUI

/// Dark robed figure silhouette — featureless, full black.
struct SilhouetteView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Canvas { ctx, size in
                let cx = size.width / 2

                // ── Head ──────────────────────────────────────────────────────
                let headR = w * 0.09
                let headCY = h * 0.14
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx - headR, y: headCY - headR,
                                          width: headR * 2, height: headR * 2.1)),
                    with: .color(.black)
                )

                // ── Hood ─────────────────────────────────────────────────────
                var hood = Path()
                hood.move(to:    CGPoint(x: cx - w*0.16, y: headCY + headR * 0.6))
                hood.addCurve(to: CGPoint(x: cx + w*0.16, y: headCY + headR * 0.6),
                              control1: CGPoint(x: cx - w*0.22, y: headCY - headR * 1.5),
                              control2: CGPoint(x: cx + w*0.22, y: headCY - headR * 1.5))
                hood.closeSubpath()
                ctx.fill(hood, with: .color(.black))

                // ── Robe body ────────────────────────────────────────────────
                var robe = Path()
                let shoulderY = headCY + headR * 1.0
                let hemY = h * 0.96
                robe.move(to:    CGPoint(x: cx - w*0.14, y: shoulderY))
                robe.addCurve(to: CGPoint(x: cx - w*0.32, y: hemY),
                              control1: CGPoint(x: cx - w*0.22, y: shoulderY + h*0.15),
                              control2: CGPoint(x: cx - w*0.34, y: hemY - h*0.2))
                robe.addLine(to: CGPoint(x: cx + w*0.32, y: hemY))
                robe.addCurve(to: CGPoint(x: cx + w*0.14, y: shoulderY),
                              control1: CGPoint(x: cx + w*0.34, y: hemY - h*0.2),
                              control2: CGPoint(x: cx + w*0.22, y: shoulderY + h*0.15))
                robe.closeSubpath()
                ctx.fill(robe, with: .color(.black))

                // ── Sleeve hints ─────────────────────────────────────────────
                for side: CGFloat in [-1, 1] {
                    var sleeve = Path()
                    sleeve.move(to:    CGPoint(x: cx + side * w*0.14, y: shoulderY + h*0.08))
                    sleeve.addCurve(to: CGPoint(x: cx + side * w*0.4,  y: h*0.6),
                                    control1: CGPoint(x: cx + side * w*0.28, y: shoulderY + h*0.15),
                                    control2: CGPoint(x: cx + side * w*0.42, y: h*0.5))
                    sleeve.addLine(to: CGPoint(x: cx + side * w*0.34, y: h*0.6))
                    sleeve.addCurve(to: CGPoint(x: cx + side * w*0.1,  y: shoulderY + h*0.12),
                                    control1: CGPoint(x: cx + side * w*0.36, y: h*0.5),
                                    control2: CGPoint(x: cx + side * w*0.2,  y: shoulderY + h*0.2))
                    sleeve.closeSubpath()
                    ctx.fill(sleeve, with: .color(.black))
                }
            }
        }
    }
}

#Preview {
    SilhouetteView()
        .frame(width: 220, height: 420)
        .background(Color(red: 0.05, green: 0.03, blue: 0.08))
}

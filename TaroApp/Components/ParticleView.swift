import SwiftUI
import Combine

private struct Particle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: CGFloat
    var speed: CGFloat
    var drift: CGFloat   // horizontal drift per tick

    static func random(in size: CGSize) -> Particle {
        Particle(
            x: CGFloat.random(in: 0...size.width),
            y: CGFloat.random(in: -size.height...0),
            size: CGFloat.random(in: 1.5...4),
            opacity: CGFloat.random(in: 0.2...0.8),
            speed: CGFloat.random(in: 0.4...1.4),
            drift: CGFloat.random(in: -0.3...0.3)
        )
    }
}

enum ParticleStyle {
    case stardust   // gold falling dots
    case smoke      // white upward wisps
}

struct ParticleView: View {
    let style: ParticleStyle
    var count: Int = 60

    @State private var particles: [Particle] = []
    @State private var canvasSize: CGSize = .zero

    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        Canvas { ctx, size in
            for p in particles {
                let color: Color = style == .stardust
                    ? Color(hex: "#f0d080").opacity(p.opacity)
                    : Color.white.opacity(p.opacity * 0.4)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: p.x - p.size/2, y: p.y - p.size/2,
                                          width: p.size, height: p.size)),
                    with: .color(color)
                )
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    canvasSize = geo.size
                    particles = (0..<count).map { _ in Particle.random(in: canvasSize) }
                }
            }
        )
        .onReceive(timer) { _ in
            tick()
        }
        .allowsHitTesting(false)
    }

    private func tick() {
        let h = canvasSize.height
        let w = canvasSize.width
        for i in particles.indices {
            switch style {
            case .stardust:
                particles[i].y += particles[i].speed
                particles[i].x += particles[i].drift
                if particles[i].y > h + 10 {
                    particles[i] = Particle.random(in: canvasSize)
                    particles[i].y = -8
                }
            case .smoke:
                particles[i].y -= particles[i].speed * 0.5
                particles[i].x += particles[i].drift * 0.5
                particles[i].opacity -= 0.003
                if particles[i].opacity <= 0 || particles[i].y < -20 {
                    particles[i] = Particle(
                        x: CGFloat.random(in: w*0.2...w*0.8),
                        y: h * 0.7,
                        size: CGFloat.random(in: 4...10),
                        opacity: CGFloat.random(in: 0.1...0.3),
                        speed: CGFloat.random(in: 0.3...0.8),
                        drift: CGFloat.random(in: -0.4...0.4)
                    )
                }
            }
        }
    }
}

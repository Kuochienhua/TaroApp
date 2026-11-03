import SwiftUI

/// A full tarot card with 3-D flip animation (back → front).
struct TarotCardView: View {
    let card: TarotCard
    var isFlipped: Bool = false
    var isReversed: Bool = false

    /// Standard tarot aspect ratio  63 : 88 ≈ 0.716
    static let aspectRatio: CGFloat = 63.0 / 88.0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            ZStack {
                // Back face
                CardBackView()
                    .opacity(isFlipped ? 0 : 1)

                // Front face
                CardFrontView(card: card, isReversed: isReversed)
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (0, 1, 0))
            }
            .rotation3DEffect(.degrees(isFlipped ? 0 : 180), axis: (0, 1, 0))
            .frame(width: w, height: w / TarotCardView.aspectRatio)
            .shadow(color: Color(hex: "#c9a84c").opacity(isFlipped ? 0.35 : 0.15),
                    radius: isFlipped ? 14 : 6)
        }
    }
}

#Preview {
    let m = CardMeaning(general: "", love: "", career: "", finance: "", spiritual: "", advice: "")
    let p = PositionMeaning(past: "", present: "", future: "")
    let card = TarotCard(id: 0, name: "愚者", nameEn: "The Fool", arcana: "major", number: 0,
                         keywords: ["自由"], symbolKey: "fool", colorHex: "#FFD700",
                         element: "風", themes: ["新開始"],
                         upright: m, reversed: m, positionMeaning: p)
    VStack(spacing: 24) {
        TarotCardView(card: card, isFlipped: false)
            .frame(width: 120)
        TarotCardView(card: card, isFlipped: true)
            .frame(width: 120)
    }
    .padding()
    .background(Color.black)
}

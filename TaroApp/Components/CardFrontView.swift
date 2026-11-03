import SwiftUI

/// Card face — shows real JPEG artwork when available, falls back to Canvas geometry art.
struct CardFrontView: View {
    let card: TarotCard
    var isReversed: Bool = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: w * 0.06)
                    .fill(Color(hex: "#12101e"))

                // Outer gold border
                RoundedRectangle(cornerRadius: w * 0.06)
                    .strokeBorder(Color(hex: "#c9a84c"), lineWidth: 1.2)

                // Inner border
                RoundedRectangle(cornerRadius: w * 0.05)
                    .inset(by: w * 0.04)
                    .strokeBorder(Color(hex: "#c9a84c").opacity(0.5), lineWidth: 0.7)

                VStack(spacing: 0) {
                    // ── Artwork ──────────────────────────────────────────────
                    if let uiImage = loadTarotImage(symbolKey: card.symbolKey) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .rotationEffect(isReversed ? .degrees(180) : .zero)
                            .padding(.horizontal, w * 0.06)
                            .padding(.top, h * 0.04)
                            .padding(.bottom, h * 0.01)
                    } else {
                        // Fallback: roman numeral + Canvas art
                        Text(romanNumeral(card.number))
                            .font(.system(size: w * 0.14, weight: .light, design: .serif))
                            .foregroundColor(Color(hex: "#c9a84c"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, h * 0.04)

                        Canvas { ctx, size in
                            drawSymbol(ctx: ctx, size: size, key: card.symbolKey,
                                       color: Color(hex: card.colorHex))
                        }
                        .frame(width: w * 0.68, height: w * 0.68)
                        .rotationEffect(isReversed ? .degrees(180) : .zero)

                        Spacer(minLength: 0)
                    }

                    // ── Card name ─────────────────────────────────────────────
                    Text(card.name)
                        .font(.system(size: w * 0.12, weight: .regular, design: .serif))
                        .foregroundColor(Color(hex: "#f0d080"))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, h * 0.03)
                }
            }
        }
    }
}

// MARK: - Image loader

private func loadTarotImage(symbolKey: String) -> UIImage? {
    guard let filename = tarotImageFilename[symbolKey] else { return nil }

    // Try folder reference path first (blue folder in Xcode)
    if let path = Bundle.main.path(forResource: filename, ofType: "jpeg",
                                   inDirectory: "Taro-Card"),
       let img = UIImage(contentsOfFile: path) { return img }

    // Fallback: files copied flat into bundle (yellow group in Xcode)
    if let img = UIImage(named: filename) { return img }
    if let img = UIImage(named: "\(filename).jpeg") { return img }

    return nil
}

private let tarotImageFilename: [String: String] = [
    // ── Major Arcana ──────────────────────────────────────────
    "fool":           "RWS1909_-_00_Fool",
    "magician":       "RWS1909_-_01_Magician",
    "high_priestess": "RWS1909_-_02_High_Priestess",
    "empress":        "RWS1909_-_03_Empress",
    "emperor":        "RWS1909_-_04_Emperor",
    "hierophant":     "RWS1909_-_05_Hierophant",
    "lovers":         "RWS1909_-_06_Lovers",
    "chariot":        "RWS1909_-_07_Chariot",
    "strength":       "RWS1909_-_08_Strength",
    "hermit":         "RWS1909_-_09_Hermit",
    "wheel":          "RWS1909_-_10_Wheel_of_Fortune",
    "justice":        "RWS1909_-_11_Justice",
    "hanged_man":     "RWS1909_-_12_Hanged_Man",
    "death":          "RWS1909_-_13_Death",
    "temperance":     "RWS1909_-_14_Temperance",
    "devil":          "RWS1909_-_15_Devil",
    "tower":          "RWS1909_-_16_Tower",
    "star":           "RWS1909_-_17_Star",
    "moon":           "RWS1909_-_18_Moon",
    "sun":            "RWS1909_-_19_Sun",
    "judgement":      "RWS1909_-_20_Judgement",
    "world":          "RWS1909_-_21_World",
    // ── Wands ─────────────────────────────────────────────────
    "wands_01": "RWS1909_-_Wands_01", "wands_02": "RWS1909_-_Wands_02",
    "wands_03": "RWS1909_-_Wands_03", "wands_04": "RWS1909_-_Wands_04",
    "wands_05": "RWS1909_-_Wands_05", "wands_06": "RWS1909_-_Wands_06",
    "wands_07": "RWS1909_-_Wands_07", "wands_08": "RWS1909_-_Wands_08",
    "wands_09": "RWS1909_-_Wands_09", "wands_10": "RWS1909_-_Wands_10",
    "wands_11": "RWS1909_-_Wands_11", "wands_12": "RWS1909_-_Wands_12",
    "wands_13": "RWS1909_-_Wands_13", "wands_14": "RWS1909_-_Wands_14",
    // ── Cups ──────────────────────────────────────────────────
    "cups_01": "RWS1909_-_Cups_01", "cups_02": "RWS1909_-_Cups_02",
    "cups_03": "RWS1909_-_Cups_03", "cups_04": "RWS1909_-_Cups_04",
    "cups_05": "RWS1909_-_Cups_05", "cups_06": "RWS1909_-_Cups_06",
    "cups_07": "RWS1909_-_Cups_07", "cups_08": "RWS1909_-_Cups_08",
    "cups_09": "RWS1909_-_Cups_09", "cups_10": "RWS1909_-_Cups_10",
    "cups_11": "RWS1909_-_Cups_11", "cups_12": "RWS1909_-_Cups_12",
    "cups_13": "RWS1909_-_Cups_13", "cups_14": "RWS1909_-_Cups_14",
    // ── Swords ────────────────────────────────────────────────
    "swords_01": "RWS1909_-_Swords_01", "swords_02": "RWS1909_-_Swords_02",
    "swords_03": "RWS1909_-_Swords_03", "swords_04": "RWS1909_-_Swords_04",
    "swords_05": "RWS1909_-_Swords_05", "swords_06": "RWS1909_-_Swords_06",
    "swords_07": "RWS1909_-_Swords_07", "swords_08": "RWS1909_-_Swords_08",
    "swords_09": "RWS1909_-_Swords_09", "swords_10": "RWS1909_-_Swords_10",
    "swords_11": "RWS1909_-_Swords_11", "swords_12": "RWS1909_-_Swords_12",
    "swords_13": "RWS1909_-_Swords_13", "swords_14": "RWS1909_-_Swords_14",
    // ── Pentacles ─────────────────────────────────────────────
    "pentacles_01": "RWS1909_-_Pentacles_01", "pentacles_02": "RWS1909_-_Pentacles_02",
    "pentacles_03": "RWS1909_-_Pentacles_03", "pentacles_04": "RWS1909_-_Pentacles_04",
    "pentacles_05": "RWS1909_-_Pentacles_05", "pentacles_06": "RWS1909_-_Pentacles_06",
    "pentacles_07": "RWS1909_-_Pentacles_07", "pentacles_08": "RWS1909_-_Pentacles_08",
    "pentacles_09": "RWS1909_-_Pentacles_09", "pentacles_10": "RWS1909_-_Pentacles_10",
    "pentacles_11": "RWS1909_-_Pentacles_11", "pentacles_12": "RWS1909_-_Pentacles_12",
    "pentacles_13": "RWS1909_-_Pentacles_13", "pentacles_14": "RWS1909_-_Pentacles_14",
]

// MARK: - Canvas fallback (unchanged geometry art)

private func drawSymbol(ctx: GraphicsContext, size: CGSize, key: String, color: Color) {
    let w = size.width
    let cx = w / 2
    let cy = size.height / 2
    let gold = Color(hex: "#c9a84c")
    ctx.fill(starPath(cx: cx, cy: cy, outerR: w*0.3, innerR: w*0.15, points: 8),
             with: .color(gold.opacity(0.6)))
    ctx.stroke(
        Path(ellipseIn: CGRect(x: cx-w*0.35, y: cy-w*0.35, width: w*0.7, height: w*0.7)),
        with: .color(gold.opacity(0.4)), lineWidth: 1.0
    )
}

// MARK: - Helpers

private func romanNumeral(_ n: Int) -> String {
    let map: [(Int, String)] = [
        (21,"XXI"),(20,"XX"),(19,"XIX"),(18,"XVIII"),(17,"XVII"),
        (16,"XVI"),(15,"XV"),(14,"XIV"),(13,"XIII"),(12,"XII"),
        (11,"XI"),(10,"X"),(9,"IX"),(8,"VIII"),(7,"VII"),
        (6,"VI"),(5,"V"),(4,"IV"),(3,"III"),(2,"II"),(1,"I"),(0,"0")
    ]
    return map.first { $0.0 == n }?.1 ?? "\(n)"
}

private func roundedRectPath(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, r: CGFloat) -> Path {
    RoundedRectangle(cornerRadius: r).path(in: CGRect(x: x, y: y, width: width, height: height))
}

#Preview {
    let m = CardMeaning(general: "", love: "", career: "", finance: "", spiritual: "", advice: "")
    let p = PositionMeaning(past: "", present: "", future: "")
    let card = TarotCard(id: 0, name: "愚者", nameEn: "The Fool", arcana: "major", number: 0,
                         keywords: ["自由"], symbolKey: "fool", colorHex: "#FFD700",
                         element: "風", themes: ["新開始"],
                         upright: m, reversed: m, positionMeaning: p)
    CardFrontView(card: card)
        .frame(width: 160, height: 224)
        .padding()
        .background(Color.black)
}

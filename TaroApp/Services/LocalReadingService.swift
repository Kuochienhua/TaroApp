import Foundation

/// Provides offline tarot card interpretations from the bundled JSON database.
/// Replaces any AI/network-based interpretation service.
struct LocalReadingService {

    // MARK: - Individual card reading

    static func interpretCard(_ drawn: DrawnCard) -> String {
        let card = drawn.card
        let meaning = card.upright
        let orientation = "正位"

        return """
        ✦ \(drawn.position) · \(card.name)（\(orientation)）✦

        \(positionPreamble(drawn.position))

        \(meaning.general)

        ◈ 愛情
        \(meaning.love)

        ◈ 事業
        \(meaning.career)

        ◈ 財運
        \(meaning.finance)
        """
    }

    // MARK: - Three-card spread overall reading

    static func interpretReading(_ cards: [DrawnCard]) -> String {
        guard cards.count >= 3 else { return "牌數不足，無法進行解讀。" }

        let past    = cards[0]
        let present = cards[1]
        let future  = cards[2]

        let pastMeaning    = past.card.upright
        let presentMeaning = present.card.upright
        let futureMeaning  = future.card.upright

        return """
        ✦ 三牌陣 · 命運之鏡 ✦

        \(openingNarrative(past: past, present: present, future: future))

        ◈ \(past.position) · \(past.card.name)（正位）
        \(pastMeaning.general)

        ◈ \(present.position) · \(present.card.name)（正位）
        \(presentMeaning.general)

        ◈ \(future.position) · \(future.card.name)（正位）
        \(futureMeaning.general)

        ✦ 命運之語 ✦
        \(synthesis(past: past, present: present, future: future))
        """
    }

    // MARK: - Private helpers

    private static func positionPreamble(_ position: String) -> String {
        switch position {
        case "過去":
            return "過去的力量如根脈深埋於靈魂之中，這張牌揭示了塑造今日的根源與已走過的課題。"
        case "現在":
            return "此刻的能量如光影交疊在你的周圍，這張牌映照出你當下所面對的真實狀態與核心能量。"
        case "未來":
            return "未來的可能性如種子靜待破土，這張牌指引著前方道路的傾向，而非不可更改的命定。"
        default:
            return ""
        }
    }

    private static func openingNarrative(past: DrawnCard, present: DrawnCard, future: DrawnCard) -> String {
        let names = "\(past.card.name)、\(present.card.name)、\(future.card.name)"
        let allKeywords = (past.card.keywords + present.card.keywords + future.card.keywords)
            .prefix(4)
            .joined(separator: "、")
        return "\(names)，三張牌如星圖在此刻交織，以「\(allKeywords)」為線索，訴說著屬於你此刻的深刻故事。"
    }

    private static func synthesis(past: DrawnCard, present: DrawnCard, future: DrawnCard) -> String {
        let pastKeyword    = past.card.keywords.first    ?? past.card.name
        let presentKeyword = present.card.keywords.first ?? present.card.name
        let futureKeyword  = future.card.keywords.first  ?? future.card.name

        let pastSuffix    = "的光芒在你的過去留下了深刻的烙印"
        let presentSuffix = "的力量此刻就在你的雙手之中"
        let futureSuffix  = "的祝福正在前方為你展開"

        return """
        \(pastKeyword)\(pastSuffix)；\
        \(presentKeyword)\(presentSuffix)；\
        而\(futureKeyword)\(futureSuffix)。\
        宇宙的訊息是：你並非命運的旁觀者，而是它的共同書寫者。\
        帶著這三張牌給你的智慧，踏出屬於你的下一步。
        """
    }
}

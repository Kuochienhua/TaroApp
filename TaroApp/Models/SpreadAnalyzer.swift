import Foundation

/// Analyses the three-card spread and generates a holistic narrative.
struct SpreadAnalysis {
    let elementInsight: String       // 元素組合分析
    let themePattern: String         // 主題模式解讀
    let energyFlow: String           // 過去→現在→未來 能量流動
    let coreMessage: String          // 核心訊息
    let advice: String               // 整體行動建議
}

struct SpreadAnalyzer {

    static func analyze(_ drawn: [DrawnCard]) -> SpreadAnalysis {
        guard drawn.count >= 3 else {
            return SpreadAnalysis(
                elementInsight: "", themePattern: "",
                energyFlow: "", coreMessage: "", advice: ""
            )
        }
        let past    = drawn[0]
        let present = drawn[1]
        let future  = drawn[2]

        return SpreadAnalysis(
            elementInsight: elementInsight(past, present, future),
            themePattern:   themePattern(past, present, future),
            energyFlow:     energyFlow(past, present, future),
            coreMessage:    coreMessage(past, present, future),
            advice:         advice(past, present, future)
        )
    }

    // MARK: - Element insight

    private static func elementInsight(_ past: DrawnCard, _ present: DrawnCard, _ future: DrawnCard) -> String {
        let elements = [past.card.element, present.card.element, future.card.element]
        let unique = Set(elements)

        // Three identical elements
        if unique.count == 1 {
            return elementTripleMessage(elements[0])
        }

        // Two identical elements
        let counts = Dictionary(elements.map { ($0, 1) }, uniquingKeysWith: +)
        if let dominant = counts.first(where: { $0.value == 2 })?.key {
            return elementDominantMessage(dominant, other: counts.keys.first { $0 != dominant } ?? "")
        }

        // All different — check for classic tensions or harmonies
        if unique.contains("火") && unique.contains("水") {
            return "火與水的力量同時出現，象徵著激情與情感之間的張力。學習讓熱情被智慧所引導，讓情感為行動賦予溫度，這正是此次牌陣最深刻的功課。"
        }
        if unique.contains("土") && unique.contains("風") {
            return "土地的穩固與風的流動在此交會。你正站在實際行動與思維革新的交叉口，讓紮實的基礎支持你的創新，用靈活的思維活化你的踏實。"
        }
        if unique.contains("靈") {
            return "靈性能量滲透在這次抽牌中，宇宙正在向你傳遞超越日常層面的訊息，請以開放而虔誠的心聆聽更高智慧的引導。"
        }
        return "三種不同的元素力量匯聚於此，代表著你的生命正處於多元力量交織的豐富時刻，每一種能量都帶來珍貴的禮物。"
    }

    private static func elementTripleMessage(_ element: String) -> String {
        switch element {
        case "火": return "三張牌皆屬火元素，能量高漲而強烈。行動力、熱情與創造力正在你的生命中全面燃燒，善用這股力量，同時留意勿因過度燃燒而耗盡自己。"
        case "水": return "三張牌皆屬水元素，情感的深流貫穿整個牌陣。此刻你的生命充滿情緒的豐富與直覺的智慧，允許自己感受，讓情感的河流帶你到達更深的真相。"
        case "土": return "三張牌皆屬土元素，腳踏實地的能量充滿牌陣。物質、身體與實際成果是此刻的核心，你正在為生命建立最堅實的基礎。"
        case "風": return "三張牌皆屬風元素，思維與溝通的能量主導一切。這是思考、計劃與表達的強大時期，讓智慧的風吹散迷霧，帶來清晰的洞見。"
        case "靈": return "三張牌皆屬靈性元素，這是極為罕見而神聖的組合。宇宙正以最高的頻率與你共鳴，這次的指引來自靈魂最深處，請以全部的存在去聆聽。"
        default:   return "強大的元素共鳴出現在牌陣中，這股一致的能量正在為你的旅程提供清晰而有力的方向。"
        }
    }

    private static func elementDominantMessage(_ dominant: String, other: String) -> String {
        let domName: String
        switch dominant {
        case "火": domName = "火的熱情與行動力"
        case "水": domName = "水的情感與直覺"
        case "土": domName = "土的穩定與實踐"
        case "風": domName = "風的思維與溝通"
        default:   domName = "靈性的指引"
        }
        let otherName: String
        switch other {
        case "火": otherName = "火元素的行動激情"
        case "水": otherName = "水元素的情感深度"
        case "土": otherName = "土元素的踏實根基"
        case "風": otherName = "風元素的清晰思維"
        default:   otherName = "靈性元素的超越視野"
        }
        return "\(domName)主導著這次牌陣的基調，同時融入了\(otherName)的輔助。讓主要的能量引領方向，讓輔助的力量為旅程添加深度。"
    }

    // MARK: - Theme pattern

    private static func themePattern(_ past: DrawnCard, _ present: DrawnCard, _ future: DrawnCard) -> String {
        let allThemes = past.card.themes + present.card.themes + future.card.themes
        let counts = Dictionary(allThemes.map { ($0, 1) }, uniquingKeysWith: +)
        let dominant = counts.sorted { $0.value > $1.value }.prefix(2).map(\.key)

        // Check for specific powerful patterns
        let allCards = [past.card, present.card, future.card]
        let majorCount = allCards.filter { $0.arcana == "major" }.count

        var patterns: [String] = []

        if majorCount == 3 {
            patterns.append("三張大阿爾克那同時出現，這是極為深刻的牌陣。命運之力正在強力運作，此刻所發生的一切都有其宏觀的靈魂意義，並非偶然。")
        } else if majorCount == 2 {
            patterns.append("兩張大阿爾克那在牌陣中發光，靈魂層面的課題與命運的引導是此次閱讀的核心主軸。")
        }

        if dominant.contains("轉化") && dominant.contains("新開始") {
            patterns.append("「轉化」與「新開始」的主題同時湧現，預示著一個完整的蛻變週期——舊的正在瓦解，新的正在誕生，你站在生命轉折的神聖門檻上。")
        } else if dominant.contains("挑戰") {
            patterns.append("挑戰的主題貫穿牌陣，但請記住：塔羅中的困難牌並非詛咒，而是靈魂成長最肥沃的土壤，每一個挑戰都在錘鍊你成為更完整的自己。")
        } else if dominant.contains("愛情") || dominant.contains("連結") {
            patterns.append("情感與連結的能量在牌陣中流淌，人際關係正是此刻生命中最重要的主題，無論是愛情、友情或自我之愛，都在呼喚你更深地投入。")
        } else if !dominant.isEmpty {
            patterns.append("「\(dominant[0])」的主題在牌陣中反覆出現，這是宇宙特別希望你關注的領域，值得深入探索與反思。")
        }

        return patterns.isEmpty
            ? "牌陣展現了豐富多元的主題，你的生命正處於一個複雜而充滿可能的時刻，每一個面向都值得細細品味。"
            : patterns.joined(separator: "\n\n")
    }

    // MARK: - Energy flow

    private static func energyFlow(_ past: DrawnCard, _ present: DrawnCard, _ future: DrawnCard) -> String {
        let pastReversed    = past.isReversed
        let presentReversed = present.isReversed
        let futureReversed  = future.isReversed
        let reversedCount   = [pastReversed, presentReversed, futureReversed].filter { $0 }.count

        let pastCard    = past.card.name
        let presentCard = present.card.name
        let futureCard  = future.card.name

        let pastDesc    = pastReversed    ? "（逆位，能量受阻或內化）" : "（正位，能量順流）"
        let presentDesc = presentReversed ? "（逆位，正面臨內在挑戰）" : "（正位，能量正在顯化）"
        let futureDesc  = futureReversed  ? "（逆位，前方仍有課題待整合）" : "（正位，能量正向展開）"

        var flow = "能量流動路徑：\n\(pastCard)\(pastDesc) → \(presentCard)\(presentDesc) → \(futureCard)\(futureDesc)\n\n"

        switch reversedCount {
        case 0:
            flow += "三張牌均為正位，能量流動順暢而清晰。過去的經歷化為養分，當下的行動充滿力量，未來的展望令人振奮。此刻你正處於一個能量高度流通的美好狀態。"
        case 1:
            if pastReversed {
                flow += "過去的能量曾經受阻或被壓抑，但這段經歷已成為你靈魂最深刻的導師。它的教訓正在當下開花，為你未來的光明道路奠定了不可或缺的基礎。"
            } else if presentReversed {
                flow += "當下的能量正在面臨內在的挑戰與整合，這是一個重要的轉化期。過去為你累積了豐厚的資糧，只需穿越眼前的迷霧，明亮的未來正在等待。"
            } else {
                flow += "過去的根基穩固，當下的行動充滿活力，而未來的能量需要更多的內在整合。這提醒你，外在成就需要配合內在的成長才能真正持久。"
            }
        case 2:
            flow += "兩張逆位牌顯示目前生命中有許多能量正在向內流動，這是深度整合與內在轉化的時期。雖然外在進展可能感覺緩慢，但內心正在發生深刻而重要的蛻變。"
        case 3:
            flow += "三張牌均為逆位，提示你需要向內探索。外在世界的路暫時閉塞，是因為靈魂正在邀請你向內尋找答案。這是蛻變最深刻的時刻，在靜止中孕育著巨大的轉化力量。"
        default:
            break
        }

        return flow
    }

    // MARK: - Core message

    private static func coreMessage(_ past: DrawnCard, _ present: DrawnCard, _ future: DrawnCard) -> String {
        // Generate a synthesized narrative linking all three cards
        let p = past.card.name
        let pr = present.card.name
        let f = future.card.name
        let pO = past.isReversed ? "逆位的" : ""
        let prO = present.isReversed ? "逆位的" : ""
        let fO = future.isReversed ? "逆位的" : ""

        return """
        這次牌陣為你描繪了一幅清晰的靈魂地圖。

        \(pO)\(p)守護著你的過去，那些走過的路、學過的課、承受過的重量，如今都化為你靈魂深處最珍貴的寶藏。

        站在當下，\(prO)\(pr)正在引導你。這張牌是此刻你最需要聆聽的聲音，它揭示了你當前所處的能量狀態，以及你現在最需要的覺察與行動。

        而\(fO)\(f)在未來的位置閃爍著光芒，它不是一個固定的命運，而是一個正在成形的可能性——你今日所播下的種子，將在這裡開花結果。

        三張牌合而觀之，訴說的是一個關於\(past.card.themes.first ?? "成長")、\(present.card.themes.first ?? "轉化")與\(future.card.themes.first ?? "未來")的故事，而你，正是這個故事最重要的作者。
        """
    }

    // MARK: - Advice

    private static func advice(_ past: DrawnCard, _ present: DrawnCard, _ future: DrawnCard) -> String {
        let allThemes = Set(past.card.themes + present.card.themes + future.card.themes)
        var advicePoints: [String] = []

        if allThemes.contains("轉化") || allThemes.contains("結束") {
            advicePoints.append("✦ 允許舊有的事物完整地結束，不要在廢墟上重建，要在新土上播種。")
        }
        if allThemes.contains("愛情") || allThemes.contains("連結") {
            advicePoints.append("✦ 在重要的關係中保持真實，脆弱是連結最短的距離。")
        }
        if allThemes.contains("行動") || allThemes.contains("意志") {
            advicePoints.append("✦ 計劃已經足夠，現在是採取具體行動的時刻，第一步永遠是最重要的。")
        }
        if allThemes.contains("靜默") || allThemes.contains("內省") {
            advicePoints.append("✦ 在行動之前，給自己一段安靜的時光，答案已在你心中等待被聽見。")
        }
        if allThemes.contains("新開始") {
            advicePoints.append("✦ 以初心面對每一天，放下過去的包袱，新的開始需要輕盈的靈魂。")
        }
        if allThemes.contains("挑戰") || allThemes.contains("陰影") {
            advicePoints.append("✦ 不要逃避眼前的挑戰，你面對的每一個困難都是靈魂在邀請你變得更強大。")
        }

        // Always add a universal closing advice
        advicePoints.append("✦ 信任這個時刻，信任你自己——宇宙從不抽到「錯誤」的牌，每一張都是為你此刻最需要的訊息而來。")

        return advicePoints.joined(separator: "\n\n")
    }
}

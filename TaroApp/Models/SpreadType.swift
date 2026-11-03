import Foundation

enum SpreadType: String, CaseIterable, Identifiable {
    case daily        = "daily"
    case classic      = "classic"
    case relationship = "relationship"
    case fiveStar     = "fiveStar"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:        return "今日指引"
        case .classic:      return "時光三牌"
        case .relationship: return "關係牌陣"
        case .fiveStar:     return "五星牌陣"
        }
    }

    var subtitle: String {
        switch self {
        case .daily:        return "單張 · 每日啟示"
        case .classic:      return "過去 · 現在 · 未來"
        case .relationship: return "自己 · 對方 · 關係"
        case .fiveStar:     return "情境 · 挑戰 · 建議 · 內在 · 結果"
        }
    }

    var cardDots: String {
        switch self {
        case .daily:        return "✦"
        case .classic:      return "✦ ✦ ✦"
        case .relationship: return "✦ ✦ ✦"
        case .fiveStar:     return "✦ ✦ ✦ ✦ ✦"
        }
    }

    var positions: [String] {
        switch self {
        case .daily:        return ["今日指引"]
        case .classic:      return ["過去", "現在", "未來"]
        case .relationship: return ["自己", "對方", "關係"]
        case .fiveStar:     return ["情境", "挑戰", "建議", "內在", "結果"]
        }
    }

    var cardCount: Int { positions.count }
}

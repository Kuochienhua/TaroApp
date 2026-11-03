import Foundation

struct TarotCard: Identifiable, Codable {
    let id: Int
    let name: String
    let nameEn: String
    let arcana: String
    let number: Int
    let keywords: [String]
    let symbolKey: String
    let colorHex: String
    let element: String          // 火 / 水 / 土 / 風 / 靈
    let themes: [String]         // 主題標籤，供牌陣分析使用
    let upright: CardMeaning
    let reversed: CardMeaning
    let positionMeaning: PositionMeaning
}

struct CardMeaning: Codable {
    let general: String
    let love: String
    let career: String
    let finance: String
    let spiritual: String
    let advice: String
}

struct PositionMeaning: Codable {
    let past: String      // 此牌在「過去」位置的特定解讀
    let present: String   // 此牌在「現在」位置的特定解讀
    let future: String    // 此牌在「未來」位置的特定解讀
}

struct DrawnCard: Identifiable {
    let id = UUID()
    let card: TarotCard
    let isReversed: Bool
    let position: String   // "過去" / "現在" / "未來"
}

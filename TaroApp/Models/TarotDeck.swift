import Foundation
import Combine

class TarotDeck: ObservableObject {
    @Published private(set) var cards: [TarotCard] = []

    init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "tarot_cards", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(TarotDeckFile.self, from: data)
        else {
            return
        }
        cards = decoded.cards
    }

    func drawCards(for spread: SpreadType) -> [DrawnCard] {
        let shuffled = cards.shuffled().prefix(spread.cardCount)
        return zip(shuffled, spread.positions).map { card, position in
            DrawnCard(card: card, isReversed: false, position: position)
        }
    }
}

// MARK: - Private helpers

private struct TarotDeckFile: Codable {
    let cards: [TarotCard]
}

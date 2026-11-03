import SwiftUI
import Combine

enum GameScene {
    case intro
    case cascade
    case table
    case question   // user states their question before drawing
    case mystic
    case drawing
    case reading
}

@MainActor
class GameStateViewModel: ObservableObject {
    @Published var currentScene: GameScene = .intro
    @Published var drawnCards: [DrawnCard] = []
    @Published var userQuestion: String = ""
    @Published var selectedSpread: SpreadType = .classic

    private let deck = TarotDeck()

    func advance() {
        withAnimation(.easeInOut(duration: 0.5)) {
            switch currentScene {
            case .intro:     currentScene = .cascade
            case .cascade:   currentScene = .table
            case .table:     currentScene = .question
            case .question:  currentScene = .mystic
            case .mystic:    currentScene = .drawing
            case .drawing:   currentScene = .reading
            case .reading:   break
            }
        }
    }

    func drawCards() {
        drawnCards = deck.drawCards(for: selectedSpread)
        advance()
    }

    func reset() {
        drawnCards = []
        userQuestion = ""
        withAnimation(.easeInOut(duration: 0.5)) {
            currentScene = .question
        }
    }
}

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

    init() {
        #if DEBUG
        applyScreenshotLaunchArguments()
        #endif
    }

    #if DEBUG
    /// App Store 截圖用：`-screenshotScene drawing|reading|mystic|table|question`
    /// 可選 `-screenshotSpread daily|classic|relationship|fiveStar`。Release 版不會編入。
    private func applyScreenshotLaunchArguments() {
        let defaults = UserDefaults.standard
        guard let sceneName = defaults.string(forKey: "screenshotScene") else { return }
        if let spreadName = defaults.string(forKey: "screenshotSpread"),
           let spread = SpreadType(rawValue: spreadName) {
            selectedSpread = spread
        }
        userQuestion = "最近工作上的轉變，會帶我走向哪裡？"
        switch sceneName {
        case "table":    currentScene = .table
        case "question": currentScene = .question
        case "mystic":   currentScene = .mystic
        case "drawing":
            drawnCards = deck.drawCards(for: selectedSpread)
            currentScene = .drawing
        case "reading":
            drawnCards = deck.drawCards(for: selectedSpread)
            currentScene = .reading
        default: break
        }
    }
    #endif

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

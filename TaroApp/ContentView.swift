import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameStateViewModel()

    var body: some View {
        ZStack {
            AppColors.mysteryBlack
                .ignoresSafeArea()

            switch gameState.currentScene {
            case .intro:
                IntroScene {
                    gameState.advance()
                }
                .transition(.opacity)

            case .cascade:
                CascadeScene {
                    gameState.advance()
                }
                .transition(.opacity)

            case .table:
                TableScene {
                    gameState.advance()
                }
                .transition(.opacity)

            case .question:
                QuestionScene(
                    question: $gameState.userQuestion,
                    selectedSpread: $gameState.selectedSpread
                ) {
                    gameState.advance()
                }
                .transition(.opacity)

            case .mystic:
                MysticScene {
                    gameState.drawCards()
                }
                .transition(.opacity)

            case .drawing:
                DrawScene(drawnCards: gameState.drawnCards) {
                    gameState.advance()
                }
                .transition(.opacity)

            case .reading:
                ReadingScene(
                    drawnCards: gameState.drawnCards,
                    userQuestion: gameState.userQuestion
                ) {
                    gameState.reset()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: gameState.currentScene)
    }
}

#Preview {
    ContentView()
}

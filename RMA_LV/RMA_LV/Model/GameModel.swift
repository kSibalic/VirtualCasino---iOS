import SwiftUI
import Combine

enum GameType: String, CaseIterable, Identifiable {
    case slots = "Slot Machine"
    case blackjack = "Blackjack"
    case roulette = "Roulette"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .slots: return "🎰"
        case .blackjack: return "🃏"
        case .roulette: return "🎲"
        }
    }
    
    var description: String {
        switch self {
        case .slots: return "Spin to match symbols and win big!"
        case .blackjack: return "Reach 21 without going over"
        case .roulette: return "Place your bets and spin the wheel"
        }
    }
}

// Game state to be shared across views
class GameState: ObservableObject {
    @Published var coins: Int = 1000
    @Published var history: [GameResult] = []
    
    func addResult(game: GameType, won: Bool, amount: Int) {
        let result = GameResult(gameType: game, won: won, amount: amount, timestamp: Date())
        history.append(result)
        
        // Limit history to last 20 results
        if history.count > 20 {
            history.removeFirst()
        }
    }
    
    func resetGame() {
        coins = 1000
        history = []
    }
}

// Structure to store game results
struct GameResult: Identifiable {
    let id = UUID()
    let gameType: GameType
    let won: Bool
    let amount: Int
    let timestamp: Date
    
    var character: Character {
        return won ? "W" : "L"
    }
    
    var color: Color {
        return won ? .green : .red
    }
}

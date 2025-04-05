import SwiftUI

struct LobbyView: View {
    @StateObject var gameState = GameState()
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                Text("🎲 RMA Casino 💰")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Balance display
                HStack {
                    Text("Balance:")
                        .font(.headline)
                    Text("\(gameState.coins) coins")
                        .font(.headline)
                        .foregroundColor(.green)
                    Spacer()
                    Button(action: {
                        gameState.resetGame()
                    }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Game history
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(gameState.history) { result in
                            ZStack {
                                Circle()
                                    .fill(result.color)
                                    .frame(width: 30, height: 30)
                                
                                Text(String(result.character))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .bold()
                            }
                            .overlay(
                                Text(result.gameType.icon)
                                    .font(.system(size: 8))
                                    .padding(2)
                                    .background(Circle().fill(.white))
                                    .offset(x: 10, y: -10)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 40)
                .padding(.vertical)
                
                // Game selection
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(GameType.allCases) { game in
                            NavigationLink(destination: gameDestination(for: game)) {
                                GameCard(gameType: game)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .environmentObject(gameState)
    }
    
    // Return the appropriate view based on game type
    @ViewBuilder
    func gameDestination(for gameType: GameType) -> some View {
        switch gameType {
        case .slots:
            SlotMachineView()
        case .blackjack:
            BlackjackView()
        case .roulette:
            RouletteView()
        }
    }
}

// Card view for each game
struct GameCard: View {
    let gameType: GameType
    
    var body: some View {
        HStack {
            Text(gameType.icon)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(gameType.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(gameType.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// Preview
struct LobbyView_Previews: PreviewProvider {
    static var previews: some View {
        LobbyView()
    }
}

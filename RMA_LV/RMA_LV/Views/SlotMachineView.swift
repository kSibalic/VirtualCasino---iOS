import SwiftUI

struct SlotMachineView: View {
    @EnvironmentObject var gameState: GameState
    let symbols = ["🍒", "🍋", "🍊", "🍉", "⭐️", "7️⃣"]
    
    @State private var reel1 = "🍒"
    @State private var reel2 = "🍋"
    @State private var reel3 = "🍊"
    
    @State private var message = "Welcome! Good Luck!"
    @State private var betAmount: Int = 10
    @State private var spinning = false
    @State private var recentResults: [Character] = []
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with back button
            HStack {
                NavigationLink(destination: LobbyView().navigationBarHidden(true)) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Lobby")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("💰 \(gameState.coins) coins")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            // Recent results for this game only
            HStack(spacing: 5) {
                ForEach(recentResults, id: \.self) { result in
                    ZStack {
                        Circle()
                            .fill(result == "W" ? Color.green : Color.red)
                            .frame(width: 25, height: 25)
                        
                        Text(result == "W" ? "W" : "L")
                            .font(.caption)
                            .foregroundColor(.white)
                            .bold()
                    }
                }
            }
            .padding(.top)

            // Game title
            Text("🎰 Slot Machine 🎰")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Slots
            HStack(spacing: 20) {
                SlotReel(symbol: reel1, spinning: spinning)
                SlotReel(symbol: reel2, spinning: spinning)
                SlotReel(symbol: reel3, spinning: spinning)
            }
            
            // Game status
            Text(message)
                .foregroundColor(.gray)
                .font(.subheadline)
                .frame(height: 20)
            
            // Bet amount slider
            VStack {
                Text("Bet: \(betAmount) coins")
                    .font(.subheadline)
                Slider(value: Binding(
                    get: { Double(self.betAmount) },
                    set: { self.betAmount = Int($0) }
                ), in: 10...100, step: 10)
                .padding(.horizontal)
            }
            
            // Bet & MaxBet buttons
            HStack(spacing: 10) {
                Button(action: spinRegular) {
                    Text("Spin (-\(betAmount))")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(width: 150)
                        .background(gameState.coins < betAmount ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(gameState.coins < betAmount || spinning)
                
                Button(action: spinMaxBet) {
                    Text("MaxBet (-100)")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(width: 150)
                        .background(gameState.coins < 100 ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(gameState.coins < 100 || spinning)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    // Spin function
    func spin(isMaxBet: Bool = false) {
        spinning = true
        message = "Spinning..."
        let cost = isMaxBet ? 100 : betAmount
        let reward = isMaxBet ? 500 : betAmount * 5
        
        gameState.coins -= cost
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            reel1 = symbols.randomElement()!
            reel2 = symbols.randomElement()!
            reel3 = symbols.randomElement()!
            
            if reel1 == reel2 && reel2 == reel3 {
                message = "You Win \(reward)! 🎉"
                gameState.coins += reward
                recentResults.append("W")
                gameState.addResult(game: .slots, won: true, amount: reward)
            } else {
                message = "Try Again! 😢"
                recentResults.append("L")
                gameState.addResult(game: .slots, won: false, amount: cost)
            }

            if recentResults.count > 10 {
                recentResults.removeFirst()
            }
            
            spinning = false
        }
    }
    
    // Spin amount
    func spinRegular() {
        spin()
    }
    
    // MaxBet spin
    func spinMaxBet() {
        spin(isMaxBet: true)
    }
}

// Slot animation (unchanged)
struct SlotReel: View {
    var symbol: String
    var spinning: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Text(symbol)
            .font(.system(size: 64))
            .rotation3DEffect(.degrees(spinning ? rotation: 0), axis: (x: 1, y: 0, z: 0))
            .onChange(of: spinning) { isSpinning in
                if isSpinning {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        rotation += 360
                    }
                }
            }
    }
}

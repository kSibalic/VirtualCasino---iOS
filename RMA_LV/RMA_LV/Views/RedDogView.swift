import SwiftUI

struct RedDogView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.presentationMode) var presentationMode
    
    let ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
    let suits = ["♠️", "♥️", "♦️", "♣️"]
    
    @State private var card1 = "🂠"
    @State private var card2 = "🂠"
    @State private var card3 = "🂠"
    
    @State private var message = "Place your bet!"
    @State private var betAmount: Int = 10
    @State private var dealing = false
    @State private var gameStage = 0 // 0: initial, 1: two cards dealt, 2: third card revealed
    @State private var recentResults: [Character] = []
    
    // Calculate the spread between two cards
    func calculateSpread(rank1: String, rank2: String) -> Int {
        let index1 = ranks.firstIndex(of: rank1) ?? 0
        let index2 = ranks.firstIndex(of: rank2) ?? 0
        
        // Return the number of cards in between (excluding the cards themselves)
        return abs(index1 - index2) - 1
    }
    
    // Get rank and suit from a card string
    func getRankAndSuit(from card: String) -> (rank: String, suit: String) {
        if card.count <= 2 {
            let rank = String(card.prefix(1))
            let suit = String(card.suffix(1))
            return (rank, suit)
        } else {
            let rank = String(card.prefix(2))
            let suit = String(card.suffix(1))
            return (rank, suit)
        }
    }
    
    // Get just the rank from a card string
    func getRank(from card: String) -> String {
        let (rank, _) = getRankAndSuit(from: card)
        return rank
    }
    
    // Generate a random card excluding already dealt cards
    func getRandomCard(excluding: [String] = []) -> String {
        var newCard: String
        repeat {
            let randomRank = ranks.randomElement()!
            let randomSuit = suits.randomElement()!
            newCard = randomRank + randomSuit
        } while excluding.contains(newCard)
        
        return newCard
    }
    
    // Calculate payout based on spread
    func calculatePayout(bet: Int, spread: Int) -> Int {
        switch spread {
        case 0: // Pair - no spread (special case)
            return bet * 5
        case 1:
            return bet * 5
        case 2:
            return bet * 4
        case 3:
            return bet * 2
        default:
            return bet
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with back button
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
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
            Text("🃏 Red Dog 🐶")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Cards
            HStack(spacing: 30) {
                RedDogCardView(card: card1, flipped: gameStage >= 1)
                RedDogCardView(card: gameStage >= 2 ? card3 : "🂠", flipped: gameStage >= 2)
                RedDogCardView(card: card2, flipped: gameStage >= 1)
            }
            .padding(.vertical, 20)
            
            // Game status
            Text(message)
                .foregroundColor(.gray)
                .font(.subheadline)
                .frame(height: 20)
            
            // Bet amount slider - shown only before dealing cards
            if gameStage == 0 {
                VStack {
                    Text("Bet: \(betAmount) coins")
                        .font(.subheadline)
                    Slider(value: Binding(
                        get: { Double(self.betAmount) },
                        set: { self.betAmount = Int($0) }
                    ), in: 10...100, step: 10)
                    .padding(.horizontal)
                }
            }

            
            // Game buttons
            HStack(spacing: 10) {
                if gameStage == 0 {
                    // Initial state - Bet & Deal button
                    Button(action: {
                        if gameState.coins >= betAmount {
                            gameState.coins -= betAmount
                            dealInitialCards()
                        }
                    }) {
                        Text("Bet & Deal (-\(betAmount))")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(width: 200)
                            .background(gameState.coins < betAmount ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(gameState.coins < betAmount || dealing)
                } else if gameStage == 1 {
                    // In-game state - Draw third card or fold
                    Button(action: drawThirdCard) {
                        Text("Draw Card")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(width: 150)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(dealing)
                    
                    Button(action: fold) {
                        Text("Fold")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(width: 150)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(dealing)
                } else if gameStage == 2 {
                    // Game over state - New Game button
                    Button(action: resetGame) {
                        Text("New Game")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(width: 150)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
    
    // Deal initial two cards
    func dealInitialCards() {
        dealing = true
        message = "Dealing cards..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Get first two cards
            let firstCard = getRandomCard()
            let secondCard = getRandomCard(excluding: [firstCard])
            
            // Sort the cards by rank
            let rank1 = ranks.firstIndex(of: getRank(from: firstCard)) ?? 0
            let rank2 = ranks.firstIndex(of: getRank(from: secondCard)) ?? 0
            
            if rank1 == rank2 {
                // Pair - special case
                card1 = firstCard
                card2 = secondCard
                message = "Pair! Draw third card to see if you get three of a kind."
                gameStage = 1
            } else if rank1 < rank2 {
                card1 = firstCard
                card2 = secondCard
            } else {
                card1 = secondCard
                card2 = firstCard
            }
            
            if rank1 != rank2 {
                let spread = calculateSpread(rank1: getRank(from: card1), rank2: getRank(from: card2))
                
                if spread == 0 {
                    message = "No spread! Consecutive ranks - try again."
                    gameState.coins += betAmount  // Refund the bet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        resetGame()
                    }
                } else {
                    message = "Spread: \(spread). Draw third card or fold."
                    gameStage = 1
                }
            }
            
            dealing = false
        }
    }
    
    // Handle the special case for pairs
    func dealThirdCardForPair() {
        dealing = true
        let thirdCard = getRandomCard(excluding: [card1, card2])
        card3 = thirdCard
        
        let rank1 = getRank(from: card1)
        let rank3 = getRank(from: card3)
        
        if rank1 == rank3 {
            message = "Three of a kind! You win 11:1!"
            gameState.coins += betAmount * 11
            recentResults.append("W")
            gameState.addResult(game: .redDog, won: true, amount: betAmount * 11)
        } else {
            message = "Not three of a kind. You lose."
            recentResults.append("L")
            gameState.addResult(game: .redDog, won: false, amount: betAmount)
        }
        
        if recentResults.count > 10 {
            recentResults.removeFirst()
        }
        
        gameStage = 2
        dealing = false
    }
    
    // Draw third card and determine outcome
    func drawThirdCard() {
        dealing = true
        message = "Drawing third card..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Check if we're dealing with a pair
            if getRank(from: card1) == getRank(from: card2) {
                dealThirdCardForPair()
                return
            }
            
            // Draw third card
            let thirdCard = getRandomCard(excluding: [card1, card2])
            card3 = thirdCard
            
            // Get numerical values for comparison
            let rank1Index = ranks.firstIndex(of: getRank(from: card1)) ?? 0
            let rank2Index = ranks.firstIndex(of: getRank(from: card2)) ?? 0
            let rank3Index = ranks.firstIndex(of: getRank(from: card3)) ?? 0
            
            let spread = calculateSpread(rank1: getRank(from: card1), rank2: getRank(from: card2))
            let payoutMultiplier = calculatePayout(bet: betAmount, spread: spread)
            
            // Check if third card is between the first two
            if rank3Index > rank1Index && rank3Index < rank2Index {
                message = "You win! Payout \(payoutMultiplier) coins! 🎉"
                gameState.coins += payoutMultiplier
                recentResults.append("W")
                gameState.addResult(game: .redDog, won: true, amount: payoutMultiplier - betAmount)
            } else {
                message = "You lose! Card not in range. 😢"
                recentResults.append("L")
                gameState.addResult(game: .redDog, won: false, amount: betAmount)
            }
            
            if recentResults.count > 10 {
                recentResults.removeFirst()
            }
            
            gameStage = 2
            dealing = false
        }
    }
    
    func fold() {
        message = "You folded. Deal new cards."
        gameStage = 0
    }
    
    func resetGame() {
        card1 = "🂠"
        card2 = "🂠"
        card3 = "🂠"
        message = "Place your bet!"
        gameStage = 0
        dealing = false
    }
}

// Card view component
struct RedDogCardView: View {
    var card: String
    var flipped: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 80, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                )
                .shadow(radius: 3)

            if flipped {
                let components = getComponents(from: card)

                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(components.rank)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isRed(suit: components.suit) ? .red : .black)
                            Text(components.suit)
                                .font(.system(size: 12))
                                .foregroundColor(isRed(suit: components.suit) ? .red : .black)
                        }
                        .padding(5)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(components.suit)
                                .font(.system(size: 12))
                                .foregroundColor(isRed(suit: components.suit) ? .red : .black)
                            Text(components.rank)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isRed(suit: components.suit) ? .red : .black)
                        }
                        .rotationEffect(.degrees(180))
                        .padding(5)
                    }
                }
                .frame(width: 80, height: 120)
            } else {
                // Card back
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green)
                    .frame(width: 75, height: 115)
                    .overlay(
                        Image(systemName: "aspectratio")
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
        }
        .rotation3DEffect(
            .degrees(flipped ? 0 : 180),
            axis: (x: 0.0, y: 1.0, z: 0.0)
        )
        .animation(.easeInOut(duration: 0.5), value: flipped)
    }
    
    func isRed(suit: String) -> Bool {
        return suit == "♥️" || suit == "♦️"
    }
    
    // Helper to get components from card string
    func getComponents(from card: String) -> (rank: String, suit: String) {
        if card.count <= 2 {
            let rank = String(card.prefix(1))
            let suit = String(card.suffix(1))
            return (rank, suit)
        } else {
            let rank = String(card.prefix(2))
            let suit = String(card.suffix(1))
            return (rank, suit)
        }
    }
}

#Preview {
    let gameState = GameState()
    gameState.coins = 1000
    
    return RedDogView()
        .environmentObject(gameState)
}

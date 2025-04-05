import SwiftUI

struct Card: Identifiable {
    let id = UUID()
    let rank: String
    let suit: String
    var value: Int
    var isFaceDown: Bool = false
    
    var description: String {
        return "\(rank)\(suit)"
    }
}

class BlackjackGame: ObservableObject {
    @Published var playerCards: [Card] = []
    @Published var dealerCards: [Card] = []
    @Published var gameStatus: String = "Place your bet"
    @Published var gameInProgress: Bool = false
    @Published var revealDealerCard: Bool = false
    
    let ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    let suits = ["♠️", "♥️", "♦️", "♣️"]
    
    var deck: [Card] = []
    
    func newGame() {
        playerCards = []
        dealerCards = []
        gameStatus = "Place your bet"
        gameInProgress = false
        revealDealerCard = false
        createDeck()
    }
    
    func createDeck() {
        deck = []
        for suit in suits {
            for (index, rank) in ranks.enumerated() {
                let value = index + 1 > 10 ? 10 : index + 1
                deck.append(Card(rank: rank, suit: suit, value: value))
            }
        }
        deck.shuffle()
    }
    
    func startGame() {
        if deck.isEmpty {
            createDeck()
        }
        
        playerCards = []
        dealerCards = []
        gameInProgress = true
        revealDealerCard = false
        
        // Deal initial cards
        playerCards.append(drawCard())
        dealerCards.append(drawCard())
        playerCards.append(drawCard())
        dealerCards.append(drawCard(isFaceDown: true))
        
        gameStatus = "Your move"
        
        // Check for natural blackjack
        if calculateScore(cards: playerCards) == 21 {
            stand()
        }
    }
    
    func hit() {
        guard gameInProgress else { return }
        
        playerCards.append(drawCard())
        let score = calculateScore(cards: playerCards)
        
        if score > 21 {
            gameStatus = "Bust! You lose."
            gameInProgress = false
            revealDealerCard = true
            return
        }
        
        if score == 21 {
            stand()
        }
    }
    
    func stand() {
        guard gameInProgress else { return }
        
        gameInProgress = false
        revealDealerCard = true
        
        // Reveal dealer's face down card
        if let index = dealerCards.firstIndex(where: { $0.isFaceDown }) {
            dealerCards[index].isFaceDown = false
        }
        
        // Dealer draws until 17 or higher
        var dealerScore = calculateScore(cards: dealerCards)
        while dealerScore < 17 {
            dealerCards.append(drawCard())
            dealerScore = calculateScore(cards: dealerCards)
        }
        
        // Determine winner
        let playerScore = calculateScore(cards: playerCards)
        
        if dealerScore > 21 || playerScore > dealerScore {
            gameStatus = "You win!"
        } else if dealerScore > playerScore {
            gameStatus = "Dealer wins!"
        } else {
            gameStatus = "Push (Tie)"
        }
    }
    
    func drawCard(isFaceDown: Bool = false) -> Card {
        if deck.isEmpty {
            createDeck()
        }
        
        var card = deck.removeFirst()
        card.isFaceDown = isFaceDown
        return card
    }
    
    func calculateScore(cards: [Card]) -> Int {
        var score = 0
        var aces = 0
        
        for card in cards {
            if card.isFaceDown { continue }
            
            if card.rank == "A" {
                aces += 1
                score += 11
            } else {
                score += card.value
            }
        }
        
        // Adjust for aces if needed
        while score > 21 && aces > 0 {
            score -= 10
            aces -= 1
        }
        
        return score
    }
}

struct BlackjackView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var blackjackGame = BlackjackGame()
    @State private var betAmount: Int = 10
    @State private var recentResults: [Character] = []
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            Text("🃏 Blackjack 🃏")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Dealer's cards
            VStack(alignment: .leading) {
                Text("Dealer: \(blackjackGame.revealDealerCard ? "\(blackjackGame.calculateScore(cards: blackjackGame.dealerCards))" : "")")
                    .font(.headline)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 5) {
                        ForEach(blackjackGame.dealerCards) { card in
                            CardView(card: card)
                        }
                    }
                }
                .frame(height: 100)
            }
            .padding()
            .background(Color.green.opacity(0.3))
            .cornerRadius(8)
            
            // Game status
            Text(blackjackGame.gameStatus)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(height: 30)
            
            // Player's cards
            VStack(alignment: .leading) {
                Text("Your Hand: \(blackjackGame.calculateScore(cards: blackjackGame.playerCards))")
                    .font(.headline)
                
                ScrollView(.horizontal) {
                    HStack(spacing: 5) {
                        ForEach(blackjackGame.playerCards) { card in
                            CardView(card: card)
                        }
                    }
                }
                .frame(height: 100)
            }
            .padding()
            .background(Color.blue.opacity(0.3))
            .cornerRadius(8)
            
            // Bet controls - Only show when game is not in progress and not showing results
            if !blackjackGame.gameInProgress && blackjackGame.gameStatus == "Place your bet" {
                VStack {
                    // Bet slider with new range: 10 to 100 with increments of 10
                    HStack {
                        Text("Bet:")
                        Slider(value: Binding(
                            get: { Double(self.betAmount) },
                            set: { self.betAmount = Int(($0 / 10).rounded() * 10) }
                        ), in: 10...100, step: 10)
                        Text("\(betAmount)")
                    }
                    .padding(.horizontal)
                    
                    // Deal button
                    Button(action: {
                        if gameState.coins >= betAmount {
                            gameState.coins -= betAmount
                            blackjackGame.startGame()
                        }
                    }) {
                        Text("Deal (-\(betAmount))")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(gameState.coins >= betAmount ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(gameState.coins < betAmount)
                }
            } else if blackjackGame.gameInProgress {
                // Game action buttons - only shown during active game
                HStack(spacing: 20) {
                    Button(action: blackjackGame.hit) {
                        Text("Hit")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: blackjackGame.stand) {
                        Text("Stand")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            } else if !blackjackGame.gameInProgress && blackjackGame.gameStatus != "Place your bet" {
                // Play Again button - only shown when game is finished (not in progress and not in "Place your bet" state)
                Button(action: {
                    // Process game results
                    let playerWon = blackjackGame.gameStatus.contains("win")
                    let pushGame = blackjackGame.gameStatus.contains("Push")
                    
                    if playerWon {
                        let winnings = betAmount * 2
                        gameState.coins += winnings
                        recentResults.append("W")
                        gameState.addResult(game: .blackjack, won: true, amount: winnings - betAmount)
                    } else if pushGame {
                        // Return bet for push
                        gameState.coins += betAmount
                    } else {
                        recentResults.append("L")
                        gameState.addResult(game: .blackjack, won: false, amount: betAmount)
                    }
                    
                    // Limit recent results
                    if recentResults.count > 10 {
                        recentResults.removeFirst()
                    }
                    
                    blackjackGame.newGame()
                }) {
                    Text("Play Again")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            blackjackGame.createDeck()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

struct CardView: View {
    let card: Card
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(card.isFaceDown ? Color.green : Color.white)
                .frame(width: 70, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1)
                )
            
            if !card.isFaceDown {
                VStack {
                    HStack {
                        Text(card.rank)
                            .font(.caption)
                            .bold()
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Text(card.suit)
                        .font(.title)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text(card.rank)
                            .font(.caption)
                            .bold()
                            .rotationEffect(.degrees(180))
                    }
                }
                .padding(5)
                .foregroundColor(card.suit == "♥️" || card.suit == "♦️" ? .red : .black)
            } else {
                Text("🃏")
                    .font(.largeTitle)
            }
        }
    }
}

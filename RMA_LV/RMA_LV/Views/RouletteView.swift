import SwiftUI

struct RouletteNumber: Identifiable {
    let id = UUID()
    let number: Int
    let color: Color
    let isEven: Bool
    
    init(number: Int) {
        self.number = number
        
        let redNumbers = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
        
        if number == 0 {
            self.color = .green
            self.isEven = false
        } else if redNumbers.contains(number) {
            self.color = .red
            self.isEven = number % 2 == 0
        } else {
            self.color = .black
            self.isEven = number % 2 == 0
        }
    }
}

enum BetType: String, CaseIterable, Identifiable {
    case straight = "Straight (Single Number)"
    case red = "Red"
    case black = "Black"
    case even = "Even"
    case odd = "Odd"
    case low = "Low (1-18)"
    case high = "High (19-36)"
    case dozen1 = "1st Dozen (1-12)"
    case dozen2 = "2nd Dozen (13-24)"
    case dozen3 = "3rd Dozen (25-36)"
    
    var id: String { self.rawValue }
    
    var payout: Int {
        switch self {
        case .straight: return 35
        case .red, .black, .even, .odd, .low, .high: return 1
        case .dozen1, .dozen2, .dozen3: return 2
        }
    }
    
    var description: String {
        switch self {
        case .straight: return "35:1"
        case .red, .black, .even, .odd, .low, .high: return "1:1"
        case .dozen1, .dozen2, .dozen3: return "2:1"
        }
    }
}

struct Bet {
    let type: BetType
    let amount: Int
    var selectedNumber: Int? = nil // Only used for straight bets
}

class RouletteGame: ObservableObject {
    @Published var currentNumber: RouletteNumber?
    @Published var gameStatus: String = "Place your bets"
    @Published var isSpinning: Bool = false
    @Published var showResult: Bool = false
    @Published var winAmount: Int = 0
    @Published var recentNumbers: [RouletteNumber] = []
    
    let allNumbers: [RouletteNumber] = Array(0...36).map { RouletteNumber(number: $0) }
    
    func spin(bet: Bet) -> (won: Bool, payout: Int) {
        isSpinning = true
        gameStatus = "Wheel is spinning..."
        
        // Simulate spinning delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Get random number
            let randomIndex = Int.random(in: 0...36)
            self.currentNumber = self.allNumbers[randomIndex]
            
            // Add to recent numbers
            self.recentNumbers.insert(self.currentNumber!, at: 0)
            if self.recentNumbers.count > 10 {
                self.recentNumbers.removeLast()
            }
            
            self.isSpinning = false
            self.showResult = true
            
            // Determine if bet won
            if let currentNumber = self.currentNumber {
                self.checkWin(number: currentNumber, bet: bet)
            }
        }
        
        return (false, 0) // Default return, actual result is processed async
    }
    
    func checkWin(number: RouletteNumber, bet: Bet) {
        var won = false
        
        switch bet.type {
        case .straight:
            if let selectedNumber = bet.selectedNumber, selectedNumber == number.number {
                won = true
            }
        case .red:
            if number.color == .red {
                won = true
            }
        case .black:
            if number.color == .black {
                won = true
            }
        case .even:
            if number.number != 0 && number.isEven {
                won = true
            }
        case .odd:
            if number.number != 0 && !number.isEven {
                won = true
            }
        case .low:
            if number.number >= 1 && number.number <= 18 {
                won = true
            }
        case .high:
            if number.number >= 19 && number.number <= 36 {
                won = true
            }
        case .dozen1:
            if number.number >= 1 && number.number <= 12 {
                won = true
            }
        case .dozen2:
            if number.number >= 13 && number.number <= 24 {
                won = true
            }
        case .dozen3:
            if number.number >= 25 && number.number <= 36 {
                won = true
            }
        }
        
        if won {
            winAmount = bet.amount * (bet.type.payout + 1) // Total including original bet
            gameStatus = "You won \(winAmount) coins!"
        } else {
            winAmount = 0
            gameStatus = "Better luck next time!"
        }
    }
    
    func resetGame() {
        currentNumber = nil
        gameStatus = "Place your bets"
        isSpinning = false
        showResult = false
        winAmount = 0
    }
}

struct RouletteView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var rouletteGame = RouletteGame()
    @State private var selectedBetType: BetType = .red
    @State private var betAmount: Int = 10
    @State private var selectedNumber: Int = 0
    @State private var showNumberPicker: Bool = false
    @State private var recentResults: [Character] = [] // W for win, L for loss
    
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
            
            // Recent results
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
            
            Text("🎰 Roulette 🎰")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Recent numbers display
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(rouletteGame.recentNumbers) { number in
                        ZStack {
                            Circle()
                                .fill(number.color)
                                .frame(width: 35, height: 35)
                            Text("\(number.number)")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                }
            }
            .frame(height: 45)
            .padding(.horizontal)
            
            // Current spin result
            if rouletteGame.isSpinning {
                Text("Spinning...")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(height: 100)
            } else if let currentNumber = rouletteGame.currentNumber, rouletteGame.showResult {
                ZStack {
                    Circle()
                        .fill(currentNumber.color)
                        .frame(width: 100, height: 100)
                    Text("\(currentNumber.number)")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .frame(height: 120)
            } else {
                Image(systemName: "circle.grid.3x3.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.green)
                    .frame(width: 100, height: 100)
            }
            
            // Game status
            Text(rouletteGame.gameStatus)
                .font(.headline)
                .frame(height: 30)
            
            if !rouletteGame.isSpinning && !rouletteGame.showResult {
                // Betting controls
                VStack(spacing: 12) {
                    // Bet type selector
                    Picker("Bet Type", selection: $selectedBetType) {
                        ForEach(BetType.allCases) { betType in
                            Text("\(betType.rawValue) (\(betType.description))")
                                .tag(betType)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedBetType) { newValue in
                        showNumberPicker = (newValue == .straight)
                    }
                    
                    // Number selector for straight bets
                    if selectedBetType == .straight {
                        HStack {
                            Text("Choose Number:")
                            Spacer()
                            Picker("Number", selection: $selectedNumber) {
                                ForEach(0...36, id: \.self) { number in
                                    Text("\(number)")
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 80)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Bet amount slider
                    HStack {
                        Text("Bet:")
                        Slider(value: Binding(
                            get: { Double(self.betAmount) },
                            set: { self.betAmount = Int(($0 / 10).rounded() * 10) }
                        ), in: 10...100, step: 10)
                        Text("\(betAmount)")
                    }
                    .padding(.horizontal)
                    
                    // Spin button
                    Button(action: {
                        if gameState.coins >= betAmount {
                            gameState.coins -= betAmount
                            
                            let bet = Bet(
                                type: selectedBetType,
                                amount: betAmount,
                                selectedNumber: selectedBetType == .straight ? selectedNumber : nil
                            )
                            
                            let result = rouletteGame.spin(bet: bet)
                        }
                    }) {
                        Text("Spin (-\(betAmount))")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(gameState.coins >= betAmount ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(gameState.coins < betAmount || rouletteGame.isSpinning)
                }
            } else if rouletteGame.showResult {
                // Play again button
                Button(action: {
                    // Process results
                    if rouletteGame.winAmount > 0 {
                        gameState.coins += rouletteGame.winAmount
                        recentResults.append("W")
                        gameState.addResult(game: .roulette, won: true, amount: rouletteGame.winAmount - betAmount)
                    } else {
                        recentResults.append("L")
                        gameState.addResult(game: .roulette, won: false, amount: betAmount)
                    }
                    
                    // Limit recent results
                    if recentResults.count > 10 {
                        recentResults.removeFirst()
                    }
                    
                    rouletteGame.resetGame()
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
            
            // Payout information
            if !rouletteGame.isSpinning && !rouletteGame.showResult {
                Group {
                    Divider()
                    Text("Payouts:")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Straight: 35:1 | Red/Black: 1:1 | Even/Odd: 1:1")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Low/High: 1:1 | Dozens: 2:1")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundColor(.gray)
                .padding(.horizontal)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}

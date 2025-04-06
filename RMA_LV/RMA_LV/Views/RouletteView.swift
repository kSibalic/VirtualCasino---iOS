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
    @Published var rotationAngle: Double = 0
    @Published var wheelSpeed: Double = 0
    @Published var selectedWheelIndex: Int = 0
    
    let allNumbers: [RouletteNumber] = Array(0...36).map { RouletteNumber(number: $0) }
    // Roulette wheel number arrangement (European style)
    let wheelNumbers = [0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10, 5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26]
    
    func spin(bet: Bet) -> (won: Bool, payout: Int) {
        isSpinning = true
        gameStatus = "Wheel is spinning..."
        
        // Initialize spinning animation
        let randomRotations = Double.random(in: 5...10) // Random number of full rotations
        let randomIndex = Int.random(in: 0...36)
        selectedWheelIndex = randomIndex
        
        // Calculate necessary angle
        let targetPosition = getWheelPosition(for: wheelNumbers[randomIndex])
        let totalRotation = (randomRotations * 360) + targetPosition
        
        // Start wheel animation
        wheelSpeed = 720 // Initial speed (deg/sec)
        
        // Simulate spinning with decreasing speed
        var currentAngle = rotationAngle
        let spinDuration = 4.0 // Seconds for spin
        
        withAnimation(.easeOut(duration: spinDuration)) {
            rotationAngle += totalRotation
        }
        
        // Simulate spinning delay
        DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration) {
            // Get result number
            self.currentNumber = self.allNumbers[self.wheelNumbers[randomIndex]]
            
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
    
    // Calculate the position on the wheel for a given number
    func getWheelPosition(for number: Int) -> Double {
        if let index = wheelNumbers.firstIndex(of: number) {
            return Double(index) * (360.0 / Double(wheelNumbers.count))
        }
        return 0
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

struct RouletteWheel: View {
    let numbers: [Int]
    @Binding var rotationAngle: Double
    let size: CGFloat
    
    init(numbers: [Int], rotationAngle: Binding<Double>, size: CGFloat = 200) {
        self.numbers = numbers
        self._rotationAngle = rotationAngle
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Outer wheel
            Circle()
                .fill(Color.brown)
                .frame(width: size, height: size)
            
            // Pockets
            ForEach(0..<numbers.count, id: \.self) { index in
                let angle = Double(index) * (360.0 / Double(numbers.count))
                let number = numbers[index]
                let color: Color = number == 0 ? .green : (
                    [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36].contains(number) ? .red : .black
                )
                
                PocketView(number: number, color: color, angle: angle, size: size * 0.9)
            }
            
            // Center circle
            Circle()
                .fill(Color(UIColor.darkGray))
                .frame(width: size * 0.15, height: size * 0.15)
            
            // Ball indicator
            Circle()
                .fill(Color.white)
                .frame(width: 10, height: 10)
                .offset(y: -size/2 + 15)
        }
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: 0, y: 0, z: 1),
            anchor: .center
        )
    }
}

struct PocketView: View {
    let number: Int
    let color: Color
    let angle: Double
    let size: CGFloat
    
    var body: some View {
        VStack {
            Text("\(number)")
                .font(.system(size: 10))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(color)
                .clipShape(Circle())
        }
        .offset(y: -size/2 + 25)
        .rotationEffect(.degrees(angle))
    }
}

struct RouletteView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.presentationMode) var presentationMode
    
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
            
            // Spinning wheel animation or result
            ZStack {
                if rouletteGame.isSpinning {
                    RouletteWheel(
                        numbers: rouletteGame.wheelNumbers,
                        rotationAngle: $rouletteGame.rotationAngle,
                        size: 200
                    )
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
                } else {
                    RouletteWheel(
                        numbers: rouletteGame.wheelNumbers,
                        rotationAngle: $rouletteGame.rotationAngle,
                        size: 200
                    )
                    .opacity(0.8)
                }
            }
            .frame(height: 220)
            
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

#Preview {
    let gameState = GameState()
    gameState.coins = 1000
    
    return RouletteView()
        .environmentObject(gameState)
}

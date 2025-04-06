import SwiftUI

@main
struct RMA_LVApp: App {
    @StateObject private var gameState = GameState()
    
    var body: some Scene {
        WindowGroup {
            LobbyView()
                .environmentObject(gameState)
        }
    }
}

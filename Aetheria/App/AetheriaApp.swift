import SwiftUI

@main
struct AetheriaApp: App {
    @StateObject private var vm = GameViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(vm: vm)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}

/// Switches between the menu flow and the game screen.
struct RootView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        Group {
            if vm.inGame {
                GameContainerView(vm: vm)
            } else {
                MainMenuView(vm: vm)
            }
        }
        .onAppear {
            SoundManager.shared.setup()
        }
    }
}

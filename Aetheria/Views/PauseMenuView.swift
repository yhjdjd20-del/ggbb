import SwiftUI

/// Pause menu with shortcuts to journal, settings, save & exit.
struct PauseMenuView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            FullscreenDim()
            Panel(title: L.t("pause.title")) {
                VStack(spacing: 10) {
                    Text("\(vm.session.heroName) · \(L.t("common.level")) \(vm.session.level) · \(formatPlayTime(vm.session.stats.playTime))")
                        .font(.subheadline)
                        .foregroundColor(.dimText)
                    MenuButton(label: L.t("pause.resume"), icon: "play.fill", accent: Color(hex: "#3FD97C")) {
                        vm.showPause = false
                    }
                    HStack(spacing: 10) {
                        MenuButton(label: L.t("inv.title"), icon: "bag.fill") {
                            vm.showPause = false
                            vm.showInventory = true
                        }
                        MenuButton(label: L.t("skill.title"), icon: "star.fill") {
                            vm.showPause = false
                            vm.showSkills = true
                        }
                        MenuButton(label: L.t("pause.journal"), icon: "book.fill") {
                            vm.showPause = false
                            vm.showQuests = true
                        }
                    }
                    MenuButton(label: L.t("pause.save"), icon: "square.and.arrow.down.fill", accent: Color(hex: "#FFD95E")) {
                        vm.saveGame(silent: false)
                    }
                    MenuButton(label: L.t("pause.settings"), icon: "gearshape.fill", accent: Color(hex: "#9AA3B2")) {
                        vm.showSettings = true
                    }
                    MenuButton(label: L.t("pause.quit"), icon: "house.fill", accent: Color(hex: "#FF4D6D")) {
                        vm.quitToMenu()
                    }
                }
                .frame(width: 420)
            }
        }
    }
}

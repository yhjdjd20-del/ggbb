import SwiftUI

/// Pause menu with shortcuts to journal, settings, save & exit.
struct PauseMenuView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            FullscreenDim()
            Panel(title: L.t("pause.title")) {
                VStack(spacing: 8) {
                    Text("\(vm.session.heroName) · \(L.t("common.level")) \(vm.session.level) · \(formatPlayTime(vm.session.stats.playTime))")
                        .font(.subheadline)
                        .foregroundColor(.dimText)
                    statChips
                    MenuButton(label: L.t("pause.resume"), icon: "play.fill", accent: Color(hex: "#3FD97C")) {
                        vm.showPause = false
                    }
                    HStack(spacing: 8) {
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
                    MenuButton(label: L.t("travel.title"), icon: "sparkles", accent: Color(hex: "#B45CFF")) {
                        vm.showPause = false
                        vm.showTravel = true
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
                .frame(width: 340)
            }
        }
    }

    private var statChips: some View {
        let derived = vm.derivedStats()
        return VStack(spacing: 4) {
            Text(L.t("pause.stats"))
                .font(.caption)
                .foregroundColor(.dimText)
            HStack(spacing: 8) {
                chip("⚔ \(Int(derived.attack))")
                chip("✦ \(Int(derived.magicPower))")
                chip("🛡 \(Int(derived.defense))")
                chip("❤ \(Int(derived.maxHP))")
            }
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(hex: "#2A3350"))
            .cornerRadius(7)
    }
}

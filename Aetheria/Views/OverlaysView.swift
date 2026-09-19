import SwiftUI

// MARK: - Death

struct DeathView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color(hex: "#30060C").opacity(0.92).ignoresSafeArea()
            VStack(spacing: 10) {
                Text("☠")
                    .font(.system(size: 64))
                Text(L.t("death.title"))
                    .font(.system(size: 52, weight: .black))
                    .foregroundColor(Color(hex: "#FF4D6D"))
                Text(L.t("death.sub"))
                    .foregroundColor(.dimText)
                Text("\(L.t("death.lost")): \(vm.deathPenalty()) \(L.t("common.gold"))")
                    .foregroundColor(.gold)
                    .padding(.top, 4)
                Text("⚔ \(vm.session.stats.kills) · 👑 \(vm.session.stats.bossesKilled) · ⏱ \(formatPlayTime(vm.session.stats.playTime))")
                    .font(.subheadline)
                    .foregroundColor(.dimText)
                HStack(spacing: 12) {
                    MenuButton(label: L.t("death.respawn"), icon: "heart.fill", accent: Color(hex: "#3FD97C")) {
                        vm.respawn()
                    }
                    MenuButton(label: L.t("death.menu"), icon: "house.fill", accent: Color(hex: "#9AA3B2")) {
                        vm.quitToMenu()
                    }
                }
                .frame(width: 440)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Victory

struct VictoryView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color(hex: "#0A1A2E").opacity(0.94).ignoresSafeArea()
            VStack(spacing: 10) {
                Text("☀")
                    .font(.system(size: 64))
                Text(L.t("victory.title"))
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "#FFD95E"), Color(hex: "#FF7B2E")], startPoint: .leading, endPoint: .trailing)
                    )
                Text(L.t("victory.sub"))
                    .foregroundColor(.dimText)
                Panel(title: L.t("victory.stats")) {
                    VStack(spacing: 6) {
                        StatRow(label: L.t("victory.kills"), value: "\(vm.session.stats.kills)")
                        StatRow(label: L.t("victory.bosses"), value: "\(vm.session.stats.bossesKilled)/3")
                        StatRow(label: L.t("victory.quests"), value: "\(vm.session.stats.questsDone)")
                        StatRow(label: L.t("victory.chests"), value: "\(vm.session.stats.chestsOpened)")
                        StatRow(label: L.t("victory.time"), value: formatPlayTime(vm.session.stats.playTime))
                    }
                    .frame(width: 340)
                }
                HStack(spacing: 12) {
                    MenuButton(label: "🗺 " + L.t("common.continue"), icon: "play.fill", accent: Color(hex: "#3FD97C")) {
                        vm.continueAfterVictory()
                    }
                    MenuButton(label: L.t("victory.menu"), icon: "house.fill", accent: Color(hex: "#9AA3B2")) {
                        vm.quitToMenu()
                    }
                }
                .frame(width: 440)
            }
        }
    }
}

// MARK: - Sign reading

struct SignView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            FullscreenDim()
            Panel {
                VStack(spacing: 12) {
                    Image(uiImage: TextureFactory.uiImage("sign"))
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(height: 68)
                    Text(vm.signText)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(width: 420)
                    SmallButton(label: L.t("common.close")) {
                        vm.closeSign()
                    }
                }
            }
        }
    }
}


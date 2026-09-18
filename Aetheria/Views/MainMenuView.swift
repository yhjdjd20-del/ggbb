import SwiftUI

enum MenuScreen: Equatable {
    case main
    case slots
    case create(slot: Int)
    case howto
    case achievements
    case settings
}

/// Menu flow root: switches between menu screens (state-driven, no NavigationStack).
struct MainMenuView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var settings = AppSettings.shared
    @State private var screen: MenuScreen = .main

    var body: some View {
        ZStack {
            menuBackground
            switch screen {
            case .main:
                mainScreen
            case .slots:
                SaveSlotView(vm: vm, onBack: { screen = .main }, onCreate: { screen = .create(slot: $0) })
            case .create(let slot):
                CharacterCreateView(vm: vm, slot: slot, onBack: { screen = .slots })
            case .howto:
                HowToPlayView(onBack: { screen = .main })
            case .achievements:
                AchievementsView(onBack: { screen = .main })
            case .settings:
                SettingsView(onBack: { screen = .main })
            }
        }
        .onAppear {
            SoundManager.shared.setup()
            SoundManager.shared.playMusic(theme: "menu")
            // Warm up procedural textures off the main thread.
            DispatchQueue.global(qos: .userInitiated).async {
                TextureFactory.preloadEssential()
            }
        }
    }

    private var menuBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#060818"), Color(hex: "#141B3D"), Color(hex: "#2A1A4E")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            HStack {
                Spacer()
                Image(uiImage: TextureFactory.uiImage("portal_2"))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: 420)
                    .opacity(0.85)
                    .padding(.trailing, 60)
                Spacer()
            }
            .opacity(0.5)
        }
    }

    private var hasAnySave: Bool {
        (0..<SaveManager.slotCount).contains { SaveManager.exists(slot: $0) }
    }

    private var appVersion: String {
        "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
    }

    private var mainScreen: some View {
        HStack(spacing: 0) {
            // Title side.
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                Text("AETHERIA")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "#B45CFF"), Color(hex: "#7DF9FF")], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: Color(hex: "#B45CFF").opacity(0.5), radius: 24)
                Text(L.t("menu.subtitle"))
                    .font(.title3)
                    .foregroundColor(.dimText)
                Spacer()
                Text("\(appVersion) · SpriteKit + SwiftUI")
                    .font(.caption)
                    .foregroundColor(.dimText.opacity(0.7))
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Buttons side.
            VStack(spacing: 12) {
                Spacer()
                if hasAnySave {
                    MenuButton(label: L.t("menu.continue"), icon: "play.fill", accent: Color(hex: "#3FD97C")) {
                        vm.continueLatest()
                    }
                }
                MenuButton(label: L.t("menu.slots"), icon: "gamecontroller.fill") {
                    screen = .slots
                }
                MenuButton(label: L.t("menu.howto"), icon: "book.fill", accent: Color(hex: "#FFD95E")) {
                    screen = .howto
                }
                MenuButton(label: L.t("menu.ach"), icon: "trophy.fill", accent: Color(hex: "#B45CFF")) {
                    screen = .achievements
                }
                MenuButton(label: L.t("menu.settings"), icon: "gearshape.fill", accent: Color(hex: "#9AA3B2")) {
                    screen = .settings
                }
                Spacer()
            }
            .padding(40)
            .frame(maxWidth: 380)
        }
    }
}

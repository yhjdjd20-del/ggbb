import SwiftUI
import SpriteKit
import UIKit

/// Owns the SKScene for the lifetime of the game screen.
final class SceneHolder: ObservableObject {
    let scene: GameScene

    init(vm: GameViewModel) {
        let scene = GameScene(size: GameScene.logicalSize, viewModel: vm, levelId: vm.session.currentLevel)
        self.scene = scene
        vm.scene = scene
    }
}

/// Game screen: SpriteKit view + touch controls + HUD + modal overlays.
struct GameContainerView: View {
    @ObservedObject var vm: GameViewModel
    @ObservedObject var settings = AppSettings.shared
    @StateObject private var holder: SceneHolder

    init(vm: GameViewModel) {
        self.vm = vm
        _holder = StateObject(wrappedValue: SceneHolder(vm: vm))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                SpriteView(scene: holder.scene, preferredFramesPerSecond: 60)
                    .ignoresSafeArea()

                // Top HUD strip. Geometry-based spacing keeps it usable on the
                // compact landscape viewport of iPhone SE.
                VStack {
                    HStack(alignment: .top, spacing: 8) {
                        questTracker(topInset: proxy.safeAreaInsets.top)
                        Spacer(minLength: 4)
                        if settings.showMinimap {
                            MinimapView(vm: vm)
                                .scaleEffect(min(1, max(0.78, proxy.size.width / 700)))
                        }
                        menuButtons
                    }
                    .padding(.horizontal, max(8, proxy.safeAreaInsets.leading + 6))
                    .padding(.top, max(6, proxy.safeAreaInsets.top + 2))
                    Spacer()
                }

                if !vm.modalOpen {
                    TouchControlsView(vm: vm)
                        .padding(.leading, proxy.safeAreaInsets.leading)
                        .padding(.trailing, proxy.safeAreaInsets.trailing)
                        .padding(.bottom, proxy.safeAreaInsets.bottom)
                }

                if vm.showInventory { InventoryView(vm: vm) }
                if vm.showSkills { SkillTreeView(vm: vm) }
                if vm.showQuests { QuestLogView(vm: vm) }
                if vm.showDialogue { DialogueOverlayView(vm: vm) }
                if vm.showShop { ShopView(vm: vm) }
                if vm.showPause { PauseMenuView(vm: vm) }
                if vm.showSign { SignView(vm: vm) }
                if vm.showDeath { DeathView(vm: vm) }
                if vm.showVictory { VictoryView(vm: vm) }
                if vm.showTravel { TravelView(vm: vm) }
                if vm.showSettings {
                    ZStack {
                        FullscreenDim()
                        SettingsView(onBack: { vm.showSettings = false })
                    }
                }
            }
        }
        .statusBar(hidden: true)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if vm.inGame && !vm.modalOpen {
                vm.showPause = true
            }
        }
    }

    private func questTracker(topInset: CGFloat) -> some View {
        Group {
            if let title = vm.trackedQuestTitle() {
                Button(action: { vm.showQuests = true }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if let progress = vm.trackedQuestProgress() {
                            Text(progress)
                                .font(.caption2)
                                .foregroundColor(.dimText)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.45))
                    .cornerRadius(7)
                }
                .padding(.top, max(54, 94 - topInset))
            }
        }
    }

    private var menuButtons: some View {
        VStack(spacing: 5) {
            hudButton(icon: "bag.fill") { vm.showInventory = true }
            ZStack(alignment: .topTrailing) {
                hudButton(icon: "star.fill") { vm.showSkills = true }
                if vm.session.skillPoints > 0 || vm.session.statPoints > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .offset(x: 4, y: -4)
                }
            }
            hudButton(icon: "book.fill") { vm.showQuests = true }
            hudButton(icon: "pause.fill") { vm.showPause = true }
        }
    }

    private func hudButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            SoundManager.shared.play("click")
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .background(Color.black.opacity(0.45))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.panelBorder, lineWidth: 1))
        }
    }
}

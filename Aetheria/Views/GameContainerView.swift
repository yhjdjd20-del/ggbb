import SwiftUI
import SpriteKit
import UIKit

/// Owns the SKScene for the lifetime of the game screen.
final class SceneHolder: ObservableObject {
    let scene: GameScene

    init(vm: GameViewModel) {
        let scene = GameScene(size: CGSize(width: 1280, height: 720), viewModel: vm, levelId: vm.session.currentLevel)
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
        ZStack {
            SpriteView(scene: holder.scene, preferredFramesPerSecond: 60)
                .ignoresSafeArea()

            // Top HUD strip.
            VStack {
                HStack(alignment: .top, spacing: 10) {
                    questTracker
                    Spacer()
                    if settings.showMinimap {
                        MinimapView(vm: vm)
                    }
                    menuButtons
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
                Spacer()
            }

            // Touch controls (transparent containers pass touches through).
            if !vm.modalOpen {
                TouchControlsView(vm: vm)
            }

            // Modal overlays.
            if vm.showInventory { InventoryView(vm: vm) }
            if vm.showSkills { SkillTreeView(vm: vm) }
            if vm.showQuests { QuestLogView(vm: vm) }
            if vm.showDialogue { DialogueOverlayView(vm: vm) }
            if vm.showShop { ShopView(vm: vm) }
            if vm.showPause { PauseMenuView(vm: vm) }
            if vm.showSign { SignView(vm: vm) }
            if vm.showDeath { DeathView(vm: vm) }
            if vm.showVictory { VictoryView(vm: vm) }
            if vm.showSettings {
                ZStack {
                    FullscreenDim()
                    SettingsView(onBack: { vm.showSettings = false })
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

    // MARK: - Quest tracker

    private var questTracker: some View {
        Group {
            if let title = vm.trackedQuestTitle() {
                Button(action: { vm.showQuests = true }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                        if let progress = vm.trackedQuestProgress() {
                            Text(progress)
                                .font(.caption2)
                                .foregroundColor(.dimText)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.45))
                    .cornerRadius(8)
                }
                .padding(.top, 116)
            }
        }
    }

    // MARK: - Menu buttons

    private var menuButtons: some View {
        VStack(spacing: 8) {
            hudButton(icon: "bag.fill") { vm.showInventory = true }
            ZStack(alignment: .topTrailing) {
                hudButton(icon: "star.fill") { vm.showSkills = true }
                if vm.session.skillPoints > 0 || vm.session.statPoints > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
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
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(Color.black.opacity(0.45))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.panelBorder, lineWidth: 1))
        }
    }
}

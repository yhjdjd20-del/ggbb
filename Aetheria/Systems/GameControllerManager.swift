import Foundation
import GameController

/// Hardware keyboard (GCKeyboard) + MFi gamepad support.
/// Keyboard events write into GameViewModel.input; the stick is polled live.
final class GameControllerManager {
    static let shared = GameControllerManager()

    weak var input: InputState?

    var activeGamepad: GCExtendedGamepad? {
        for controller in GCController.controllers() {
            if let pad = controller.extendedGamepad { return pad }
        }
        return nil
    }

    private var pollTimer: Timer?

    private init() {
        NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect, object: nil, queue: .main
        ) { [weak self] note in
            if let kb = note.object as? GCKeyboard { self?.attach(keyboard: kb) }
        }
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect, object: nil, queue: .main
        ) { [weak self] _ in self?.attachGamepads() }
        if let kb = GCKeyboard.coalesced { attach(keyboard: kb) }
        attachGamepads()

        // Poll gamepad buttons (edge-triggered) at 60 Hz.
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.pollGamepad()
        }
    }

    private var prevButtons: Set<String> = []

    private func pollGamepad() {
        guard let pad = activeGamepad, let input else {
            prevButtons = []
            return
        }
        var now: Set<String> = []
        func edge(_ name: String, _ pressed: Bool, _ action: () -> Void) {
            if pressed {
                now.insert(name)
                if !prevButtons.contains(name) { action() }
            }
        }
        edge("A", pad.buttonA.isPressed) { input.queueJump() }
        edge("X", pad.buttonX.isPressed) { input.queueAttack() }
        edge("B", pad.buttonB.isPressed) { input.queueDash() }
        edge("Y", pad.buttonY.isPressed) { input.queueSpell() }
        edge("menu", pad.buttonMenu.isPressed) { input.queueInteract() }
        prevButtons = now
    }

    private func attachGamepads() {
        // Stick values are polled via InputState.axisX/axisY; nothing to bind.
    }

    private func attach(keyboard: GCKeyboard) {
        guard let keys = keyboard.keyboardInput else { return }
        // Movement (held)
        bind(keys, .keyA) { [weak self] down in self?.input?.keyLeft = down }
        bind(keys, .leftArrow) { [weak self] down in self?.input?.keyLeft = down }
        bind(keys, .keyD) { [weak self] down in self?.input?.keyRight = down }
        bind(keys, .rightArrow) { [weak self] down in self?.input?.keyRight = down }
        bind(keys, .keyW) { [weak self] down in self?.input?.keyUp = down }
        bind(keys, .upArrow) { [weak self] down in self?.input?.keyUp = down }
        bind(keys, .keyS) { [weak self] down in self?.input?.keyDown = down }
        bind(keys, .downArrow) { [weak self] down in self?.input?.keyDown = down }
        bind(keys, .spacebar) { [weak self] down in self?.input?.jumpHeld = down }
        // Actions (pressed edge)
        tap(keys, .spacebar) { [weak self] in self?.input?.queueJump() }
        tap(keys, .keyJ) { [weak self] in self?.input?.queueAttack() }
        tap(keys, .keyZ) { [weak self] in self?.input?.queueAttack() }
        tap(keys, .leftShift) { [weak self] in self?.input?.queueDash() }
        tap(keys, .rightShift) { [weak self] in self?.input?.queueDash() }
        tap(keys, .keyK) { [weak self] in self?.input?.queueSpell() }
        tap(keys, .keyX) { [weak self] in self?.input?.queueSpell() }
        tap(keys, .keyE) { [weak self] in self?.input?.queueInteract() }
        tap(keys, .keyQ) { [weak self] in self?.input?.queuePotion() }
    }

    private func bind(_ keys: GCKeyboardInput, _ code: GCKeyCode, _ fn: @escaping (Bool) -> Void) {
        keys.button(forKeyCode: code)?.pressedChangedHandler = { _, _, pressed in fn(pressed) }
    }

    private func tap(_ keys: GCKeyboardInput, _ code: GCKeyCode, _ fn: @escaping () -> Void) {
        keys.button(forKeyCode: code)?.pressedChangedHandler = { _, _, pressed in
            if pressed { fn() }
        }
    }
}

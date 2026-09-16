import Foundation
import CoreGraphics
import GameController

/// Shared mutable input written by SwiftUI touch controls / keyboard / gamepad,
/// read and consumed by GameScene every frame. Main thread only.
final class InputState {
    /// Horizontal axis -1...1 (joystick, A/D, arrows, gamepad stick).
    var moveX: CGFloat = 0
    /// Vertical axis -1...1 (joystick up/down, W/S — ladders).
    var moveY: CGFloat = 0

    var jumpHeld: Bool = false

    // Edge-triggered actions, set by controls, consumed by the scene.
    var jumpQueued = false
    var attackQueued = false
    var dashQueued = false
    var spellQueued = false
    var interactQueued = false
    var potionQueued = false

    // Keyboard-held movement flags (merged with the stick in `axisX/axisY`).
    var keyLeft = false
    var keyRight = false
    var keyUp = false
    var keyDown = false

    var axisX: CGFloat {
        var v = moveX
        if keyLeft { v -= 1 }
        if keyRight { v += 1 }
        // Gamepad stick
        if let pad = GameControllerManager.shared.activeGamepad {
            v += CGFloat(pad.leftThumbstick.xAxis.value)
        }
        return max(-1, min(1, v))
    }

    var axisY: CGFloat {
        var v = moveY
        if keyUp { v += 1 }
        if keyDown { v -= 1 }
        if let pad = GameControllerManager.shared.activeGamepad {
            v += CGFloat(pad.leftThumbstick.yAxis.value)
        }
        return max(-1, min(1, v))
    }

    func queueJump() { jumpQueued = true }
    func queueAttack() { attackQueued = true }
    func queueDash() { dashQueued = true }
    func queueSpell() { spellQueued = true }
    func queueInteract() { interactQueued = true }
    func queuePotion() { potionQueued = true }

    /// Called by the scene after reading the queues each frame.
    func endFrame() {
        jumpQueued = false
        attackQueued = false
        dashQueued = false
        spellQueued = false
        interactQueued = false
        potionQueued = false
    }

    func reset() {
        moveX = 0
        moveY = 0
        jumpHeld = false
        keyLeft = false
        keyRight = false
        keyUp = false
        keyDown = false
        endFrame()
    }
}

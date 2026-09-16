import SwiftUI

/// On-screen controls: left virtual joystick + right action buttons.
/// Writes directly into GameViewModel.input (consumed by GameScene).
struct TouchControlsView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                JoystickView(vm: vm)
                    .padding(.leading, 24)
                    .padding(.bottom, 24)
                Spacer()
                actionButtons
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
        }
    }

    private var actionButtons: some View {
        VStack(alignment: .trailing, spacing: 10) {
            // Contextual interact button.
            if let prompt = vm.interactPrompt {
                Button(action: { vm.input.queueInteract() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                        Text(prompt)
                            .font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#B45CFF").opacity(0.55))
                    .cornerRadius(24)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(hex: "#B45CFF"), lineWidth: 1.5))
                }
            }
            HStack(alignment: .bottom, spacing: 12) {
                // Potion with count badge.
                ZStack(alignment: .topTrailing) {
                    ControlButton(icon: "heart.fill", size: 56, color: Color(hex: "#FF4D6D")) {
                        if vm.drinkPotion() { Haptics.impact(.light) }
                    }
                    Text("\(vm.potionCount)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                }
                ControlButton(icon: "sparkles", size: 60, color: Color(hex: "#7DF9FF")) {
                    vm.input.queueSpell()
                }
                ControlButton(icon: "wind", size: 60, color: Color(hex: "#9AA3B2")) {
                    vm.input.queueDash()
                }
                JumpButton(vm: vm)
                ControlButton(icon: "flame.fill", size: 84, color: Color(hex: "#FF7B2E")) {
                    vm.input.queueAttack()
                }
            }
        }
    }
}

/// Circular action button.
struct ControlButton: View {
    var icon: String
    var size: CGFloat
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(color.opacity(0.45))
                .clipShape(Circle())
                .overlay(Circle().stroke(color, lineWidth: 2))
        }
    }
}

/// Jump supports press-and-hold (variable jump height).
struct JumpButton: View {
    @ObservedObject var vm: GameViewModel
    @State private var pressed = false

    var body: some View {
        Image(systemName: "arrow.up")
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 72, height: 72)
            .background(Color(hex: "#3FD97C").opacity(pressed ? 0.75 : 0.45))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(hex: "#3FD97C"), lineWidth: 2))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {
                            pressed = true
                            vm.input.jumpHeld = true
                            vm.input.queueJump()
                        }
                    }
                    .onEnded { _ in
                        pressed = false
                        vm.input.jumpHeld = false
                    }
            )
    }
}

/// Left virtual joystick (also drives ladders via the Y axis).
struct JoystickView: View {
    @ObservedObject var vm: GameViewModel
    @State private var knob = CGSize.zero
    private let radius: CGFloat = 52

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: radius * 2 + 44, height: radius * 2 + 44)
                Circle()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 62, height: 62)
                    .offset(knob)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                        var dx = value.location.x - center.x
                        var dy = value.location.y - center.y
                        let len = hypot(dx, dy)
                        if len > radius {
                            dx = dx / len * radius
                            dy = dy / len * radius
                        }
                        knob = CGSize(width: dx, height: dy)
                        vm.input.moveX = dx / radius
                        vm.input.moveY = -dy / radius
                    }
                    .onEnded { _ in
                        knob = .zero
                        vm.input.moveX = 0
                        vm.input.moveY = 0
                    }
            )
        }
        .frame(width: 170, height: 170)
    }
}

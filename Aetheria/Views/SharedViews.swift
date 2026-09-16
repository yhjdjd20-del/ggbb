import SwiftUI

// MARK: - Colors

extension Color {
    init(hex: String) {
        var h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if h.count == 3 { h = h.map { "\($0)\($0)" }.joined() }
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(
            red: Double((int >> 16) & 0xFF) / 255.0,
            green: Double((int >> 8) & 0xFF) / 255.0,
            blue: Double(int & 0xFF) / 255.0
        )
    }

    static let panelBg = Color(hex: "#141824").opacity(0.96)
    static let panelBorder = Color(hex: "#3A4158")
    static let gold = Color(hex: "#FFD95E")
    static let dimText = Color(hex: "#9AA3B2")
}

func rarityColor(_ rarity: Rarity) -> Color {
    Color(hex: rarity.colorHex)
}

// MARK: - Panels & buttons

struct Panel<Content: View>: View {
    var title: String?
    var content: () -> Content

    init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(spacing: 12) {
            if let title {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            content()
        }
        .padding(20)
        .background(Color.panelBg)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.panelBorder, lineWidth: 2))
        .shadow(radius: 20)
    }
}

struct MenuButton: View {
    var label: String
    var icon: String = ""
    var accent: Color = Color(hex: "#4DA3FF")
    var action: () -> Void

    var body: some View {
        Button(action: {
            SoundManager.shared.play("click")
            Haptics.selection()
            action()
        }) {
            HStack {
                if !icon.isEmpty {
                    Image(systemName: icon)
                }
                Text(label)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(accent.opacity(0.25))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent, lineWidth: 1.5))
        }
    }
}

struct SmallButton: View {
    var label: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: {
            if enabled {
                SoundManager.shared.play("click")
                action()
            }
        }) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(enabled ? .white : .gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: "#2A3350"))
                .cornerRadius(9)
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(enabled ? Color.panelBorder : Color.clear, lineWidth: 1))
        }
        .opacity(enabled ? 1 : 0.5)
    }
}

// MARK: - Item icons & rows

struct ItemIconView: View {
    var icon: String
    var rarity: Rarity?
    var size: CGFloat = 48

    var body: some View {
        Image(uiImage: TextureFactory.uiImage("icon_\(icon)"))
            .resizable()
            .interpolation(.none)
            .frame(width: size, height: size)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(rarity.map(rarityColor) ?? Color.panelBorder, lineWidth: rarity == nil ? 1 : 2)
            )
    }
}

struct StatRow: View {
    var label: String
    var value: String
    var valueColor: Color = .white

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.dimText)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(valueColor)
        }
        .font(.subheadline)
    }
}

struct FullscreenDim: View {
    var body: some View {
        Color.black.opacity(0.55).ignoresSafeArea()
    }
}

// MARK: - Helpers

/// Human-readable play time, e.g. "2:34:10".
func formatPlayTime(_ seconds: Double) -> String {
    let s = Int(seconds)
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, sec)
    }
    return String(format: "%d:%02d", m, sec)
}

func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

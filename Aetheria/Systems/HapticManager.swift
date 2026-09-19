import UIKit

/// Centralized haptics, respecting the user setting.
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard AppSettings.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard AppSettings.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

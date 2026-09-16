import UIKit

// MARK: - Display quality

enum DisplayQuality: String, Codable, CaseIterable {
    case auto, high, medium, low

    var title: String {
        switch self {
        case .auto: return L.t("set.quality.auto")
        case .high: return L.t("set.quality.high")
        case .medium: return L.t("set.quality.medium")
        case .low: return L.t("set.quality.low")
        }
    }
}

// MARK: - Device detection & display metrics

/// Detects the iPhone/iPad model and picks sensible rendering settings,
/// so the picture looks right from the SE 2020 up to the largest Pro Max.
enum DeviceProfile {
    /// Raw model identifier, e.g. "iPhone12,8". Empty on failure.
    static let modelIdentifier: String = {
        #if targetEnvironment(simulator)
            return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
        #else
            var systemInfo = utsname()
            uname(&systemInfo)
            let mirror = Mirror(reflecting: systemInfo.machine)
            return mirror.children.reduce("") { acc, element in
                guard let value = element.value as? Int8, value != 0 else { return acc }
                return acc + String(UnicodeScalar(UInt8(value)))
            }
        #endif
    }()

    /// Human-readable marketing name.
    static var marketingName: String {
        if let known = marketingNames[modelIdentifier] { return known }
        if modelIdentifier.hasPrefix("iPhone") { return "iPhone (\(modelIdentifier))" }
        if modelIdentifier.hasPrefix("iPad") { return "iPad (\(modelIdentifier))" }
        if modelIdentifier == "Simulator" { return "Simulator" }
        return modelIdentifier.isEmpty ? "Unknown" : modelIdentifier
    }

    /// Performance tier used when the graphics setting is Auto.
    static var autoTier: DisplayQuality {
        let id = modelIdentifier
        if id == "Simulator" { return .high }
        let parts = id.split(separator: ",")
        guard parts.count == 2, let major = Int(parts[0].dropFirst(6)) else { return .high }
        if id.hasPrefix("iPhone") {
            if major <= 10 { return .low }      // X and older
            if major <= 12 { return .medium }   // XR – 11, SE 2020
            return .high                        // 12 and newer
        }
        if id.hasPrefix("iPad") {
            if major >= 13 { return .high }     // M1 and newer
            if major >= 8 { return .medium }
            return .low
        }
        return .high
    }

    /// Current key-window safe area (notch / home indicator), in view points.
    /// Must be called on the main thread.
    static var currentSafeArea: UIEdgeInsets {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let window = scene.windows.first(where: { $0.isKeyWindow }) {
                return window.safeAreaInsets
            }
        }
        return .zero
    }

    // MARK: - Known models

    private static let marketingNames: [String: String] = [
        // SE line
        "iPhone8,4": "iPhone SE (2016)",
        "iPhone12,8": "iPhone SE (2020)",
        "iPhone14,6": "iPhone SE (2022)",
        // X / XS / XR
        "iPhone10,3": "iPhone X", "iPhone10,6": "iPhone X",
        "iPhone11,2": "iPhone XS", "iPhone11,4": "iPhone XS Max", "iPhone11,6": "iPhone XS Max",
        "iPhone11,8": "iPhone XR",
        // 11
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro", "iPhone12,5": "iPhone 11 Pro Max",
        // 12
        "iPhone13,1": "iPhone 12 mini", "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro", "iPhone13,4": "iPhone 12 Pro Max",
        // 13
        "iPhone14,4": "iPhone 13 mini", "iPhone14,5": "iPhone 13",
        "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max",
        // 14
        "iPhone14,7": "iPhone 14", "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
        // 15
        "iPhone15,4": "iPhone 15", "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
        // 16
        "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max",
    ]
}

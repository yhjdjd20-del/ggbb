import Foundation
import Combine

enum Difficulty: String, Codable, CaseIterable {
    case easy, normal, hard

    var title: String {
        switch self {
        case .easy: return L.t("set.easy")
        case .normal: return L.t("set.normal")
        case .hard: return L.t("set.hard")
        }
    }

    var details: String {
        switch self {
        case .easy: return L.t("set.easy.d")
        case .normal: return L.t("set.normal.d")
        case .hard: return L.t("set.hard.d")
        }
    }

    /// Multipliers applied to enemy HP / damage.
    var enemyHP: Double {
        switch self { case .easy: return 0.7; case .normal: return 1.0; case .hard: return 1.45 }
    }

    var enemyDamage: Double {
        switch self { case .easy: return 0.7; case .normal: return 1.0; case .hard: return 1.35 }
    }

    /// Fraction of gold lost on death.
    var deathPenalty: Double {
        switch self { case .easy: return 0.05; case .normal: return 0.15; case .hard: return 0.3 }
    }
}

/// Global user settings, persisted to UserDefaults. Observed by SwiftUI.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var language: AppLanguage {
        didSet { save() }
    }
    @Published var difficulty: Difficulty {
        didSet { save() }
    }
    @Published var masterVolume: Double {
        didSet { save(); SoundManager.shared.applyVolumes() }
    }
    @Published var musicVolume: Double {
        didSet { save(); SoundManager.shared.applyVolumes() }
    }
    @Published var sfxVolume: Double {
        didSet { save(); SoundManager.shared.applyVolumes() }
    }
    @Published var hapticsEnabled: Bool {
        didSet { save() }
    }
    @Published var showMinimap: Bool {
        didSet { save() }
    }
    @Published var richEffects: Bool {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard

    private init() {
        let lang = defaults.string(forKey: "language").flatMap(AppLanguage.init(rawValue:))
        // Default to Russian for RU locales, English otherwise.
        if let lang {
            language = lang
        } else if Locale.current.language.languageCode?.identifier == "ru" {
            language = .ru
        } else {
            language = .en
        }
        difficulty = defaults.string(forKey: "difficulty").flatMap(Difficulty.init(rawValue:)) ?? .normal
        masterVolume = defaults.object(forKey: "masterVolume") as? Double ?? 0.9
        musicVolume = defaults.object(forKey: "musicVolume") as? Double ?? 0.7
        sfxVolume = defaults.object(forKey: "sfxVolume") as? Double ?? 0.9
        hapticsEnabled = defaults.object(forKey: "hapticsEnabled") as? Bool ?? true
        showMinimap = defaults.object(forKey: "showMinimap") as? Bool ?? true
        richEffects = defaults.object(forKey: "richEffects") as? Bool ?? true
        displayQuality = defaults.string(forKey: "displayQuality").flatMap(DisplayQuality.init(rawValue:)) ?? .auto
    }

    /// Resolved quality (Auto -> device tier). Never `.auto`.
    var effectiveQuality: DisplayQuality {
        displayQuality == .auto ? DeviceProfile.autoTier : displayQuality
    }

    /// Particle birth-rate multiplier for the resolved quality.
    var particleScale: Double {
        var scale: Double
        switch effectiveQuality {
        case .high, .auto: scale = 1.0
        case .medium: scale = 0.7
        case .low: scale = 0.4
        }
        if !richEffects { scale *= 0.35 }
        return scale
    }

    private func save() {
        defaults.set(language.rawValue, forKey: "language")
        defaults.set(difficulty.rawValue, forKey: "difficulty")
        defaults.set(masterVolume, forKey: "masterVolume")
        defaults.set(musicVolume, forKey: "musicVolume")
        defaults.set(sfxVolume, forKey: "sfxVolume")
        defaults.set(hapticsEnabled, forKey: "hapticsEnabled")
        defaults.set(showMinimap, forKey: "showMinimap")
        defaults.set(richEffects, forKey: "richEffects")
        defaults.set(displayQuality.rawValue, forKey: "displayQuality")
    }
}

import Foundation

// MARK: - App language

enum AppLanguage: String, Codable, CaseIterable {
    case en, ru
}

/// Picks the Russian string when the app language is Russian, else English.
func localized(_ en: String, _ ru: String?) -> String {
    if AppSettings.shared.language == .ru, let ru = ru, !ru.isEmpty {
        return ru
    }
    return en
}

// MARK: - Items

enum Rarity: String, Codable, CaseIterable {
    case common, uncommon, rare, epic, legendary

    var title: String {
        switch self {
        case .common: return localized("Common", "Обычный")
        case .uncommon: return localized("Uncommon", "Необычный")
        case .rare: return localized("Rare", "Редкий")
        case .epic: return localized("Epic", "Эпический")
        case .legendary: return localized("Legendary", "Легендарный")
        }
    }

    var colorHex: String {
        switch self {
        case .common: return "#9AA3B2"
        case .uncommon: return "#3FD97C"
        case .rare: return "#3FA7F5"
        case .epic: return "#B45CFF"
        case .legendary: return "#FFB02E"
        }
    }

    var sortOrder: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
}

enum ItemType: String, Codable {
    case weapon, armor, trinket, consumable, material, keyItem
}

/// Static item data loaded from Resources/Data/items.json.
/// `stats` keys: attack, magic, defense, maxHealth, maxMana, crit (0..1),
/// moveSpeed (points/s), heal (instant HP), mana (instant MP), lifesteal (0..1).
struct ItemDefinition: Codable, Identifiable {
    var id: String
    var name: String
    var nameRu: String?
    var type: ItemType
    var rarity: Rarity
    var description: String
    var descriptionRu: String?
    var stats: [String: Double]
    var price: Int
    var icon: String
    var usable: Bool
    var maxStack: Int

    var displayName: String { localized(name, nameRu) }
    var displayDescription: String { localized(description, descriptionRu) }
}

struct InventoryItem: Codable, Identifiable {
    var id: String
    var itemId: String
    var quantity: Int

    init(itemId: String, quantity: Int = 1) {
        self.id = UUID().uuidString
        self.itemId = itemId
        self.quantity = quantity
    }
}

struct Equipment: Codable {
    var weapon: InventoryItem?
    var armor: InventoryItem?
    var trinket: InventoryItem?
}

// MARK: - Stats

struct Stats: Codable {
    var strength: Int
    var agility: Int
    var vitality: Int
    var intelligence: Int

    static var zero: Stats { Stats(strength: 0, agility: 0, vitality: 0, intelligence: 0) }
}

/// Final combat numbers after base stats + equipment + skills + class.
struct DerivedStats: Codable {
    var maxHP: Double
    var maxMana: Double
    var attack: Double
    var magicPower: Double
    var defense: Double
    var critChance: Double
    var critDamage: Double
    var moveSpeed: Double
    var lifesteal: Double
    var xpBonus: Double
    var goldBonus: Double
    var dashCooldown: Double
    var canDoubleJump: Bool
    var canDash: Bool
    var canAirAttack: Bool
    var spellCostMultiplier: Double
}

// MARK: - Skills

enum SkillBranch: String, Codable, CaseIterable {
    case might, shadow, arcane

    var title: String {
        switch self {
        case .might: return localized("Might", "Мощь")
        case .shadow: return localized("Shadow", "Тень")
        case .arcane: return localized("Arcane", "Аркана")
        }
    }
}

struct SkillRequirement: Codable {
    var skill: String
    var rank: Int
}

/// `modifiers` are applied per rank. Keys: attackPct, attackFlat, magicPct,
/// defenseFlat, maxHealthPct, maxHealthFlat, maxManaFlat, critChance,
/// moveSpeedPct, lifesteal, xpPct, goldPct, dashCooldownFlat, spellCostPct.
/// `unlock` grants an ability flag: doubleJump, dash, airAttack, secondWind.
struct SkillDefinition: Codable, Identifiable {
    var id: String
    var branch: SkillBranch
    var tier: Int
    var name: String
    var nameRu: String?
    var description: String
    var descriptionRu: String?
    var maxRank: Int
    var requires: [SkillRequirement]
    var modifiers: [String: Double]
    var unlock: String?

    var displayName: String { localized(name, nameRu) }
    var displayDescription: String { localized(description, descriptionRu) }
}

// MARK: - Quests

enum QuestKind: String, Codable {
    case main, side
}

enum QuestState: String, Codable {
    case available, active, readyToTurnIn, turnedIn
}

/// Objective `type`: kill | boss | collect | reach | talk.
/// `target`: enemy id / item id / checkpoint id / npc id.
struct QuestObjective: Codable {
    var type: String
    var target: String
    var count: Int
    var text: String
    var textRu: String?
}

struct QuestReward: Codable {
    var gold: Int
    var xp: Int
    var items: [String]
}

struct QuestDefinition: Codable, Identifiable {
    var id: String
    var kind: QuestKind
    var title: String
    var titleRu: String?
    var description: String
    var descriptionRu: String?
    var giver: String?
    var turnIn: String?
    var objectives: [QuestObjective]
    var reward: QuestReward
    var requires: [String]
    var autoAccept: Bool

    var displayTitle: String { localized(title, titleRu) }
    var displayDescription: String { localized(description, descriptionRu) }
}

struct QuestProgress: Codable {
    var id: String
    var state: QuestState
    var counts: [Int]
}

enum QuestEvent {
    case kill(enemyId: String)
    case bossDefeated(bossId: String)
    case collect(itemId: String, count: Int)
    case reach(checkpointId: String)
    case talk(npcId: String)
    case levelEnter(levelId: String)
}

// MARK: - Dialogue

struct DialogueChoice: Codable {
    var text: String
    var textRu: String?
    var next: String?
    var requiresQuest: String?
    var requiresItem: String?
    var givesQuest: String?
    var turnInQuest: String?
    var givesItem: String?
    var givesGold: Int?
    var openShop: Bool?
    var action: String?

    var displayText: String { localized(text, textRu) }
}

struct DialogueNode: Codable, Identifiable {
    var id: String
    var speaker: String
    var speakerRu: String?
    var text: String
    var textRu: String?
    var choices: [DialogueChoice]

    var displaySpeaker: String { localized(speaker, speakerRu) }
    var displayText: String { localized(text, textRu) }
}

struct DialogueTree: Codable {
    var npcId: String
    var start: String
    var nodes: [DialogueNode]
}

// MARK: - Enemies

struct LootEntry: Codable {
    var item: String
    var chance: Double
    var min: Int
    var max: Int
}

/// `behavior`: hopper | flyer | shooter | charger | ghost | mage | boss.
struct EnemyDefinition: Codable, Identifiable {
    var id: String
    var name: String
    var nameRu: String?
    var hp: Double
    var damage: Double
    var speed: Double
    var xp: Int
    var goldMin: Int
    var goldMax: Int
    var behavior: String
    var flying: Bool
    var projectileSpeed: Double
    var attackRange: Double
    var attackCooldown: Double
    var scale: Double
    var phases: Int
    var loot: [LootEntry]

    var displayName: String { localized(name, nameRu) }
}

// MARK: - Levels

struct PointData: Codable {
    var x: Double
    var y: Double
}

struct RectData: Codable {
    var x: Double
    var y: Double
    var w: Double
    var h: Double
    var type: String?
}

struct MovingPlatformData: Codable {
    var x: Double
    var y: Double
    var w: Double
    var h: Double
    var dx: Double
    var dy: Double
    var period: Double
}

struct HazardData: Codable {
    var x: Double
    var y: Double
    var w: Double
    var h: Double
    var damage: Double
    var type: String
}

struct SpawnData: Codable {
    var id: String
    var x: Double
    var y: Double
}

struct ChestData: Codable {
    var id: String
    var x: Double
    var y: Double
    var loot: [String]
    var gold: Int
}

struct CheckpointData: Codable {
    var id: String
    var x: Double
    var y: Double
}

struct SignData: Codable {
    var x: Double
    var y: Double
    var text: String
    var textRu: String?
}

struct PortalData: Codable {
    var x: Double
    var y: Double
    var target: String?
    var lockedByBoss: String?
    var isFinal: Bool?
}

struct BossData: Codable {
    var id: String
    var x: Double
    var y: Double
    var arenaX: Double?
    var arenaW: Double?
}

struct LevelData: Codable {
    var id: String
    var name: String
    var nameRu: String?
    var width: Double
    var height: Double
    var spawn: PointData
    var theme: String
    var weather: String
    var timeOfDay: Double
    var music: String
    var platforms: [RectData]
    var movingPlatforms: [MovingPlatformData]
    var ladders: [RectData]
    var hazards: [HazardData]
    var enemySpawns: [SpawnData]
    var npcs: [SpawnData]
    var chests: [ChestData]
    var checkpoints: [CheckpointData]
    var signs: [SignData]
    var portal: PortalData
    var boss: BossData?
    var tipKey: String?

    var displayName: String { localized(name, nameRu) }
}

// MARK: - Hero classes

struct HeroClass: Identifiable {
    var id: String
    var nameEn: String
    var nameRu: String
    var descEn: String
    var descRu: String
    var stats: Stats
    var weaponId: String
    var bonusSkill: String?
    var colorHex: String

    var displayName: String { localized(nameEn, nameRu) }
    var displayDescription: String { localized(descEn, descRu) }

    static let all: [HeroClass] = [
        HeroClass(
            id: "knight",
            nameEn: "Knight", nameRu: "Рыцарь",
            descEn: "A stalwart blade of the fallen Order. High health and heavy strikes.",
            descRu: "Доблестный клинок павшего Ордена. Высокое здоровье и тяжёлые удары.",
            stats: Stats(strength: 5, agility: 2, vitality: 5, intelligence: 1),
            weaponId: "sword_iron",
            bonusSkill: "m_strike",
            colorHex: "#4DA3FF"
        ),
        HeroClass(
            id: "ranger",
            nameEn: "Ranger", nameRu: "Следопыт",
            descEn: "A swift hunter of the Whispering Forest. Fast, elusive, deadly crits.",
            descRu: "Быстрый охотник Шепчущего леса. Скорость, увёртливость, смертельные криты.",
            stats: Stats(strength: 3, agility: 6, vitality: 3, intelligence: 1),
            weaponId: "blade_ranger",
            bonusSkill: "s_swift",
            colorHex: "#3FD97C"
        ),
        HeroClass(
            id: "mage",
            nameEn: "Mage", nameRu: "Маг",
            descEn: "An apprentice of the burnt Tower. Fragile body, devastating spells.",
            descRu: "Ученик сгоревшей Башни. Хрупкое тело, разрушительные заклинания.",
            stats: Stats(strength: 1, agility: 2, vitality: 3, intelligence: 7),
            weaponId: "staff_apprentice",
            bonusSkill: "a_bolt",
            colorHex: "#B45CFF"
        ),
    ]

    static func withId(_ id: String) -> HeroClass {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

// MARK: - Session & statistics

struct GameStatistics: Codable {
    var kills: Int = 0
    var deaths: Int = 0
    var jumps: Int = 0
    var dashes: Int = 0
    var chestsOpened: Int = 0
    var questsDone: Int = 0
    var goldEarned: Int = 0
    var bossesKilled: Int = 0
    var damageDealt: Double = 0
    var damageTaken: Double = 0
    var playTime: Double = 0
}

struct GameSession: Codable {
    static let currentVersion = 3

    var version: Int = currentVersion
    var slot: Int = 0
    var heroName: String = "Hero"
    var heroClass: String = "knight"
    var level: Int = 1
    var xp: Int = 0
    var statPoints: Int = 0
    var skillPoints: Int = 0
    var baseStats: Stats = Stats(strength: 3, agility: 3, vitality: 3, intelligence: 3)
    var gold: Int = 0
    var inventory: [InventoryItem] = []
    var equipment: Equipment = Equipment()
    var skills: [String: Int] = [:]
    var quests: [String: QuestProgress] = [:]
    var trackedQuest: String?
    var currentLevel: String = "forest"
    var checkpointId: String?
    var unlockedLevels: [String] = ["forest"]
    var openedChests: [String] = []
    var defeatedBosses: [String] = []
    var achievements: [String] = []
    var stats: GameStatistics = GameStatistics()
    var hp: Double = 100
    var mana: Double = 50
    var savedAt: Date = Date()

    var hero: HeroClass { HeroClass.withId(heroClass) }

    func inventoryCount(itemId: String) -> Int {
        inventory.filter { $0.itemId == itemId }.reduce(0) { $0 + $1.quantity }
    }
}

// MARK: - Shop

struct ShopItem: Identifiable {
    var id: String { itemId }
    var itemId: String
    var price: Int
    var stock: Int // -1 = infinite
}

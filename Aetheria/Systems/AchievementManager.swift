import Foundation

struct AchievementDefinition: Identifiable {
    var id: String
    var titleEn: String
    var titleRu: String
    var descEn: String
    var descRu: String
    var icon: String

    var title: String { localized(titleEn, titleRu) }
    var details: String { localized(descEn, descRu) }
}

enum AchievementEvent {
    case kill(count: Int)
    case boss(id: String)
    case level(level: Int)
    case questDone(count: Int)
    case chest(count: Int)
    case gold(amount: Int)
    case death(count: Int)
    case dash(count: Int)
    case fullClear(levelId: String)
    case victory
}

/// Local achievements (no Game Center entitlements required).
enum AchievementManager {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: "first_blood", titleEn: "First Blood", titleRu: "Первая кровь",
            descEn: "Defeat your first enemy.", descRu: "Победи первого врага.", icon: "sword"),
        AchievementDefinition(id: "slayer_50", titleEn: "Slayer", titleRu: "Истребитель",
            descEn: "Defeat 50 enemies.", descRu: "Победи 50 врагов.", icon: "axe"),
        AchievementDefinition(id: "slayer_200", titleEn: "Nightmare of Echoes", titleRu: "Кошмар эха",
            descEn: "Defeat 200 enemies.", descRu: "Победи 200 врагов.", icon: "skull"),
        AchievementDefinition(id: "boss_1", titleEn: "Stone Breaker", titleRu: "Крушитель камня",
            descEn: "Defeat the Cave Golem.", descRu: "Победи пещерного голема.", icon: "golem"),
        AchievementDefinition(id: "boss_2", titleEn: "Oathkeeper", titleRu: "Хранитель клятвы",
            descEn: "Defeat the Fallen Knight.", descRu: "Победи павшего рыцаря.", icon: "knight"),
        AchievementDefinition(id: "boss_3", titleEn: "Stormcaller", titleRu: "Зовущий бурю",
            descEn: "Defeat the Rift Dragon.", descRu: "Победи дракона Разлома.", icon: "dragon"),
        AchievementDefinition(id: "level_5", titleEn: "Rising Hero", titleRu: "Восходящий герой",
            descEn: "Reach level 5.", descRu: "Достигни 5 уровня.", icon: "star"),
        AchievementDefinition(id: "level_10", titleEn: "Legend", titleRu: "Легенда",
            descEn: "Reach level 10.", descRu: "Достигни 10 уровня.", icon: "crown"),
        AchievementDefinition(id: "quests_5", titleEn: "Helper", titleRu: "Помощник",
            descEn: "Complete 5 quests.", descRu: "Заверши 5 квестов.", icon: "scroll"),
        AchievementDefinition(id: "chests_8", titleEn: "Treasure Hunter", titleRu: "Охотник за сокровищами",
            descEn: "Open 8 chests.", descRu: "Открой 8 сундуков.", icon: "chest"),
        AchievementDefinition(id: "rich", titleEn: "Dragon Hoard", titleRu: "Драконья сокровищница",
            descEn: "Earn 2000 gold in total.", descRu: "Заработай суммарно 2000 золота.", icon: "coins"),
        AchievementDefinition(id: "persistent", titleEn: "Undying", titleRu: "Неумирающий",
            descEn: "Die 5 times and keep going.", descRu: "Умри 5 раз и продолжай путь.", icon: "ghost"),
        AchievementDefinition(id: "acrobat", titleEn: "Acrobat", titleRu: "Акробат",
            descEn: "Dash 100 times.", descRu: "Сделай 100 рывков.", icon: "dash"),
        AchievementDefinition(id: "dawn", titleEn: "Dawnbreak", titleRu: "Рассвет",
            descEn: "Finish the game.", descRu: "Пройди игру до конца.", icon: "sun"),
    ]

    /// Returns newly unlocked achievement ids for the event.
    static func check(_ event: AchievementEvent, session: GameSession) -> [String] {
        var newly: [String] = []
        func grant(_ id: String) {
            if !session.achievements.contains(id) { newly.append(id) }
        }
        switch event {
        case .kill(let c):
            if c >= 1 { grant("first_blood") }
            if c >= 50 { grant("slayer_50") }
            if c >= 200 { grant("slayer_200") }
        case .boss(let id):
            if id == "boss_golem" { grant("boss_1") }
            if id == "boss_knight" { grant("boss_2") }
            if id == "boss_dragon" { grant("boss_3") }
        case .level(let l):
            if l >= 5 { grant("level_5") }
            if l >= 10 { grant("level_10") }
        case .questDone(let c):
            if c >= 5 { grant("quests_5") }
        case .chest(let c):
            if c >= 8 { grant("chests_8") }
        case .gold(let g):
            if g >= 2000 { grant("rich") }
        case .death(let d):
            if d >= 5 { grant("persistent") }
        case .dash(let d):
            if d >= 100 { grant("acrobat") }
        case .fullClear:
            break
        case .victory:
            grant("dawn")
        }
        return newly
    }
}

/// Cross-adventure achievement collection (shown in the main menu).
enum AchievementStore {
    private static let key = "globalAchievements"

    static var unlocked: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: key) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: key) }
    }

    static func grant(_ ids: [String]) {
        var current = unlocked
        ids.forEach { current.insert($0) }
        unlocked = current
    }
}

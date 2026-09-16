import Foundation

/// Loads all bundled JSON content (items, skills, enemies, quests, dialogues,
/// levels). Resources are copied flat into the bundle, so names must be unique.
final class ContentDatabase {
    static let shared = ContentDatabase()

    let items: [String: ItemDefinition]
    let skills: [String: SkillDefinition]
    let enemies: [String: EnemyDefinition]
    let quests: [String: QuestDefinition]
    let dialogues: [String: DialogueTree]

    private var levelCache: [String: LevelData] = [:]

    private init() {
        let loadedItems: [ItemDefinition] = Self.loadJSON("items")
        items = Dictionary(uniqueKeysWithValues: loadedItems.map { ($0.id, $0) })
        let loadedSkills: [SkillDefinition] = Self.loadJSON("skills")
        skills = Dictionary(uniqueKeysWithValues: loadedSkills.map { ($0.id, $0) })
        let loadedEnemies: [EnemyDefinition] = Self.loadJSON("enemies")
        enemies = Dictionary(uniqueKeysWithValues: loadedEnemies.map { ($0.id, $0) })
        let loadedQuests: [QuestDefinition] = Self.loadJSON("quests")
        quests = Dictionary(uniqueKeysWithValues: loadedQuests.map { ($0.id, $0) })
        let loadedDialogues: [DialogueTree] = Self.loadJSON("dialogues")
        dialogues = Dictionary(uniqueKeysWithValues: loadedDialogues.map { ($0.npcId, $0) })
    }

    func level(id: String) -> LevelData {
        if let cached = levelCache[id] { return cached }
        let data: LevelData = Self.loadJSON("level_\(id)")
        levelCache[id] = data
        return data
    }

    static func loadJSON<T: Decodable>(_ name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            fatalError("Missing bundled resource: \(name).json")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            fatalError("Failed to decode \(name).json: \(error)")
        }
    }
}

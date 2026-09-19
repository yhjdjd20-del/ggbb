import Foundation

/// JSON save slots in the Documents directory.
enum SaveManager {
    static let slotCount = 3

    static func slotURL(_ slot: Int) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("save_slot_\(slot).json")
    }

    static func save(_ session: GameSession) {
        var copy = session
        copy.savedAt = Date()
        do {
            let data = try JSONEncoder().encode(copy)
            try data.write(to: slotURL(session.slot), options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    static func load(slot: Int) -> GameSession? {
        let url = slotURL(slot)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            var session = try JSONDecoder().decode(GameSession.self, from: data)
            session.slot = slot
            migrate(&session)
            return session
        } catch {
            print("Load failed: \(error)")
            return nil
        }
    }

    static func delete(slot: Int) {
        try? FileManager.default.removeItem(at: slotURL(slot))
    }

    static func exists(slot: Int) -> Bool {
        FileManager.default.fileExists(atPath: slotURL(slot).path)
    }

    /// Forward-compatible migration between save versions.
    static func migrate(_ session: inout GameSession) {
        if session.version < 2 {
            session.openedChests = []
            session.checkpointId = nil
        }
        if session.version < 3 {
            session.trackedQuest = session.quests.values.first(where: { $0.state == .active })?.id
        }
        session.version = GameSession.currentVersion
    }
}

import Foundation
import Combine
import CoreGraphics
import SpriteKit

struct ActiveDialogue {
    var npcId: String
    var nodeId: String
}

/// Central game state: session progress, quests, dialogue, shop, overlays.
/// SpriteKit reads/writes hp/mana/session on the main thread; SwiftUI observes.
final class GameViewModel: ObservableObject {
    @Published var session = GameSession()
    @Published var inGame = false
    @Published var input = InputState()
    @Published var minimap: MinimapSnapshot?
    @Published var interactPrompt: String?
    @Published var potionCount = 0

    // Overlays (any of them pauses the scene).
    @Published var showInventory = false { didSet { refreshPause() } }
    @Published var showSkills = false { didSet { refreshPause() } }
    @Published var showQuests = false { didSet { refreshPause() } }
    @Published var showPause = false { didSet { refreshPause() } }
    @Published var showSettings = false
    @Published var showDialogue = false { didSet { refreshPause() } }
    @Published var showShop = false { didSet { refreshPause() } }
    @Published var showSign = false { didSet { refreshPause() } }
    @Published var showDeath = false { didSet { refreshPause() } }
    @Published var showVictory = false { didSet { refreshPause() } }
    @Published var showTravel = false { didSet { refreshPause() } }
    @Published var activeDialogue: ActiveDialogue?
    @Published var shopItems: [ShopItem] = []
    @Published var signText = ""

    /// Live vitals (mirrored into session on save).
    var hp: Double = 100
    var mana: Double = 50

    weak var scene: GameScene?

    var modalOpen: Bool {
        showInventory || showSkills || showQuests || showPause || showDialogue
            || showShop || showSign || showDeath || showVictory || showTravel
    }

    init() {
        GameControllerManager.shared.input = input
    }

    func refreshPause() {
        if modalOpen {
            input.endFrame()
            input.moveX = 0
            input.moveY = 0
            input.jumpHeld = false
            input.keyLeft = false
            input.keyRight = false
            input.keyUp = false
            input.keyDown = false
        }
        GameControllerManager.shared.uiBlocked = modalOpen
        scene?.isPaused = modalOpen
    }

    // MARK: - Session flow

    func newGame(heroName: String, classId: String, slot: Int) {
        let hero = HeroClass.withId(classId)
        var session = GameSession()
        session.slot = slot
        session.heroName = heroName.isEmpty ? hero.displayName : heroName
        session.heroClass = classId
        session.baseStats = .zero
        session.gold = 30
        session.equipment.weapon = InventoryItem(itemId: hero.weaponId)
        session.equipment.armor = InventoryItem(itemId: "armor_cloth")
        session.inventory = [
            InventoryItem(itemId: "potion_minor", quantity: 3),
            InventoryItem(itemId: "mana_minor", quantity: 1),
        ]
        if let bonus = hero.bonusSkill {
            session.skills[bonus] = 1
        }
        self.session = session
        hp = derivedStats().maxHP
        mana = derivedStats().maxMana
        acceptAutoQuests()
        if session.quests["q_main1"] != nil {
            self.session.trackedQuest = "q_main1"
        }
        saveGame(silent: true)
        input.reset()
        inGame = true
    }

    func continueGame(slot: Int) {
        guard let loaded = SaveManager.load(slot: slot) else { return }
        session = loaded
        hp = min(max(1, loaded.hp), derivedStats().maxHP)
        mana = min(max(0, loaded.mana), derivedStats().maxMana)
        input.reset()
        inGame = true
    }

    func quitToMenu() {
        saveGame(silent: true)
        closeAllOverlays()
        inGame = false
        scene = nil
    }

    func closeAllOverlays() {
        showInventory = false
        showSkills = false
        showQuests = false
        showPause = false
        showSettings = false
        showDialogue = false
        showShop = false
        showSign = false
        showDeath = false
        showVictory = false
        showTravel = false
        activeDialogue = nil
    }

    func saveGame(silent: Bool) {
        session.hp = hp
        session.mana = mana
        SaveManager.save(session)
        if !silent {
            toast(L.t("hud.saved"))
            SoundManager.shared.play("checkpoint")
        }
    }

    func syncBadges() {
        potionCount = session.inventoryCount(itemId: "potion_minor") + session.inventoryCount(itemId: "potion_major")
        checkAchievements(.dash(count: session.stats.dashes))
    }

    func toast(_ text: String) {
        scene?.hud.toast(text)
    }

    // MARK: - Derived stats & vitals

    func derivedStats() -> DerivedStats {
        CombatFormulas.derivedStats(for: session)
    }

    func healPlayer(_ amount: Double) {
        hp = min(derivedStats().maxHP, hp + amount)
    }

    func restoreMana(_ amount: Double) {
        mana = min(derivedStats().maxMana, mana + amount)
    }

    // MARK: - XP / gold / items

    func addXP(_ amount: Int) {
        session.xp += amount
        var leveled = false
        while session.xp >= CombatFormulas.xpForLevel(session.level) {
            session.xp -= CombatFormulas.xpForLevel(session.level)
            session.level += 1
            session.skillPoints += 1
            session.statPoints += 2
            leveled = true
        }
        if leveled {
            scene?.onLevelUp()
            checkAchievements(.level(level: session.level))
        }
    }

    func addGold(_ amount: Int) {
        guard amount != 0 else { return }
        session.gold = max(0, session.gold + amount)
        if amount > 0 {
            session.stats.goldEarned += amount
            checkAchievements(.gold(amount: session.stats.goldEarned))
        }
    }

    func addItem(itemId: String, quantity: Int = 1) {
        guard let def = ContentDatabase.shared.items[itemId] else { return }
        var left = quantity
        for i in session.inventory.indices where left > 0 {
            if session.inventory[i].itemId == itemId && session.inventory[i].quantity < def.maxStack {
                let room = def.maxStack - session.inventory[i].quantity
                let take = min(room, left)
                session.inventory[i].quantity += take
                left -= take
            }
        }
        while left > 0 {
            let take = min(def.maxStack, left)
            session.inventory.append(InventoryItem(itemId: itemId, quantity: take))
            left -= take
        }
    }

    @discardableResult
    func removeItem(itemId: String, quantity: Int = 1) -> Bool {
        var left = quantity
        for i in session.inventory.indices.reversed() where left > 0 {
            if session.inventory[i].itemId == itemId {
                let take = min(session.inventory[i].quantity, left)
                session.inventory[i].quantity -= take
                left -= take
                if session.inventory[i].quantity <= 0 {
                    session.inventory.remove(at: i)
                }
            }
        }
        return left == 0
    }

    @discardableResult
    func drinkPotion() -> Bool {
        let derived = derivedStats()
        let db = ContentDatabase.shared
        for potionId in ["potion_minor", "potion_major"] {
            if session.inventoryCount(itemId: potionId) > 0 && hp < derived.maxHP * 0.999 {
                let heal = db.items[potionId]?.stats["heal"] ?? 50
                removeItem(itemId: potionId)
                healPlayer(heal)
                SoundManager.shared.play("potion")
                scene?.puff(at: scene?.player.position ?? .zero, big: false, color: SKColor(red: 0.4, green: 1, blue: 0.5, alpha: 1))
                syncBadges()
                return true
            }
        }
        toast(L.t("hud.noPotions"))
        SoundManager.shared.play("error")
        return false
    }

    @discardableResult
    func useItem(_ item: InventoryItem) -> Bool {
        guard let def = ContentDatabase.shared.items[item.itemId], def.usable else { return false }
        if item.itemId == "bomb" {
            if removeItem(itemId: item.itemId) {
                scene?.castBomb()
                syncBadges()
                return true
            }
            return false
        }
        let heal = def.stats["heal"] ?? 0
        let mp = def.stats["mana"] ?? 0
        if heal > 0 || mp > 0 {
            let needHp = heal > 0 && hp < derivedStats().maxHP
            let needMp = mp > 0 && mana < derivedStats().maxMana
            if !needHp && !needMp {
                scene?.hud.toast(L.t(heal > 0 ? "hud.fullHp" : "hud.fullMana"))
                SoundManager.shared.play("error")
                return false
            }
            removeItem(itemId: item.itemId)
            if heal > 0 { healPlayer(heal) }
            if mp > 0 { restoreMana(mp) }
            SoundManager.shared.play("potion")
            syncBadges()
            return true
        }
        return false
    }

    func equipItem(_ item: InventoryItem) {
        guard let def = ContentDatabase.shared.items[item.itemId] else { return }
        guard def.type == .weapon || def.type == .armor || def.type == .trinket else { return }
        guard let index = session.inventory.firstIndex(where: { $0.id == item.id }) else { return }
        let moving = session.inventory.remove(at: index)
        switch def.type {
        case .weapon:
            if let old = session.equipment.weapon { session.inventory.append(old) }
            session.equipment.weapon = moving
        case .armor:
            if let old = session.equipment.armor { session.inventory.append(old) }
            session.equipment.armor = moving
        default:
            if let old = session.equipment.trinket { session.inventory.append(old) }
            session.equipment.trinket = moving
        }
        SoundManager.shared.play("pickup")
        scene?.refreshDerived()
    }

    func unequip(slot: String) {
        switch slot {
        case "weapon":
            if let old = session.equipment.weapon { session.inventory.append(old); session.equipment.weapon = nil }
        case "armor":
            if let old = session.equipment.armor { session.inventory.append(old); session.equipment.armor = nil }
        default:
            if let old = session.equipment.trinket { session.inventory.append(old); session.equipment.trinket = nil }
        }
        SoundManager.shared.play("click")
        scene?.refreshDerived()
    }

    func sellItem(_ item: InventoryItem) {
        guard let def = ContentDatabase.shared.items[item.itemId], def.type != .keyItem else {
            SoundManager.shared.play("error")
            return
        }
        let qty = item.quantity
        guard removeItem(itemId: item.itemId, quantity: qty) else { return }
        let gain = max(1, def.price / 2) * qty
        addGold(gain)
        toast("\(L.t("shop.sold")): +\(gain) \(L.t("common.gold"))")
        SoundManager.shared.play("coin")
        syncBadges()
    }

    func dropItem(_ item: InventoryItem) {
        session.inventory.removeAll { $0.id == item.id }
        SoundManager.shared.play("click")
        syncBadges()
    }

    // MARK: - Skills & attributes

    func branchPoints(_ branch: SkillBranch) -> Int {
        let db = ContentDatabase.shared
        return session.skills.reduce(0) { acc, kv in
            acc + (db.skills[kv.key]?.branch == branch ? kv.value : 0)
        }
    }

    func canLearn(_ def: SkillDefinition) -> Bool {
        let rank = session.skills[def.id] ?? 0
        guard rank < def.maxRank, session.skillPoints > 0 else { return false }
        guard branchPoints(def.branch) >= def.tier * 2 else { return false }
        for req in def.requires {
            if (session.skills[req.skill] ?? 0) < req.rank { return false }
        }
        return true
    }

    func learnSkill(_ def: SkillDefinition) {
        guard canLearn(def) else {
            SoundManager.shared.play("error")
            return
        }
        session.skills[def.id] = (session.skills[def.id] ?? 0) + 1
        session.skillPoints -= 1
        SoundManager.shared.play("skill")
        toast("\(L.t("toast.skill")): \(def.displayName)")
        scene?.refreshDerived()
    }

    func addStatPoint(_ keyPath: WritableKeyPath<Stats, Int>) {
        guard session.statPoints > 0 else {
            SoundManager.shared.play("error")
            return
        }
        session.statPoints -= 1
        session.baseStats[keyPath: keyPath] += 1
        SoundManager.shared.play("click")
        scene?.refreshDerived()
    }

    func respecAttributes() {
        let spent = session.baseStats.strength + session.baseStats.agility
            + session.baseStats.vitality + session.baseStats.intelligence - 12
        guard spent > 0 else {
            toast(L.t("skill.respecNone"))
            SoundManager.shared.play("error")
            return
        }
        guard session.gold >= 500 else {
            toast(L.t("shop.poor"))
            SoundManager.shared.play("error")
            return
        }
        addGold(-500)
        session.statPoints += spent
        session.baseStats = Stats(strength: 3, agility: 3, vitality: 3, intelligence: 3)
        scene?.refreshDerived()
        toast(L.t("skill.respecDone"))
        SoundManager.shared.play("skill")
    }

    // MARK: - Chests

    func openChest(chestId: String, loot: [String], gold: Int) {
        guard !session.openedChests.contains(chestId) else { return }
        session.openedChests.append(chestId)
        session.stats.chestsOpened += 1
        addGold(gold)
        for itemId in loot {
            addItem(itemId: itemId)
            questEvent(.collect(itemId: itemId, count: session.inventoryCount(itemId: itemId)))
        }
        toast("+\(gold) \(L.t("common.gold"))")
        for itemId in loot {
            if let def = ContentDatabase.shared.items[itemId] {
                toast("+ \(def.displayName)")
            }
        }
        checkAchievements(.chest(count: session.stats.chestsOpened))
    }

    // MARK: - Quests

    func questState(_ id: String) -> QuestState? {
        session.quests[id]?.state
    }

    func isQuestAvailable(_ def: QuestDefinition) -> Bool {
        if session.quests[def.id] != nil { return false }
        return def.requires.allSatisfy { session.quests[$0]?.state == .turnedIn }
    }

    func acceptQuest(_ id: String) {
        guard let def = ContentDatabase.shared.quests[id], isQuestAvailable(def) else { return }
        var progress = QuestProgress(id: id, state: .active, counts: Array(repeating: 0, count: def.objectives.count))
        // Sync collect-type objectives with current inventory.
        for (i, obj) in def.objectives.enumerated() where obj.type == "collect" {
            progress.counts[i] = min(obj.count, session.inventoryCount(itemId: obj.target))
        }
        session.quests[id] = progress
        if session.trackedQuest == nil || def.kind == .main {
            session.trackedQuest = id
        }
        toast("\(L.t("hud.questNew")): \(def.displayTitle)")
        SoundManager.shared.play("quest")
        checkQuestCompletion(id)
    }

    func acceptAutoQuests() {
        for def in ContentDatabase.shared.quests.values where def.autoAccept && isQuestAvailable(def) {
            acceptQuest(def.id)
        }
    }

    func questEvent(_ event: QuestEvent) {
        let db = ContentDatabase.shared
        for (id, var progress) in session.quests where progress.state == .active {
            guard let def = db.quests[id] else { continue }
            var changed = false
            while progress.counts.count < def.objectives.count {
                progress.counts.append(0)
                changed = true
            }
            for (i, obj) in def.objectives.enumerated() {
                if progress.counts[i] >= obj.count { continue }
                switch (event, obj.type) {
                case (.kill(let enemyId), "kill") where enemyId == obj.target:
                    progress.counts[i] += 1
                    changed = true
                case (.bossDefeated(let bossId), "boss") where bossId == obj.target:
                    progress.counts[i] += 1
                    changed = true
                case (.talk(let npcId), "talk") where npcId == obj.target:
                    progress.counts[i] += 1
                    changed = true
                case (.reach(let cpId), "reach") where cpId == obj.target:
                    progress.counts[i] += 1
                    changed = true
                case (.levelEnter(let levelId), "enter") where levelId == obj.target:
                    progress.counts[i] += 1
                    changed = true
                case (.collect(let itemId, let total), "collect") where itemId == obj.target:
                    let synced = min(obj.count, total)
                    if synced != progress.counts[i] {
                        progress.counts[i] = synced
                        changed = true
                    }
                default: break
                }
            }
            if changed {
                session.quests[id] = progress
                checkQuestCompletion(id)
            }
        }
    }

    private func checkQuestCompletion(_ id: String) {
        guard let def = ContentDatabase.shared.quests[id],
              var progress = session.quests[id],
              progress.state == .active
        else { return }
        let done = zip(def.objectives, progress.counts).allSatisfy { $0.count <= $1 }
        guard done else { return }
        if def.turnIn == nil {
            // Auto-complete quests pay out immediately.
            turnInQuest(id)
        } else {
            progress.state = .readyToTurnIn
            session.quests[id] = progress
            toast("\(L.t("hud.questDone")): \(def.displayTitle)")
            SoundManager.shared.play("questDone")
        }
    }

    @discardableResult
    func turnInQuest(_ id: String) -> Bool {
        guard let def = ContentDatabase.shared.quests[id],
              let progress = session.quests[id],
              progress.state == .active || progress.state == .readyToTurnIn
        else { return false }
        let done = zip(def.objectives, progress.counts).allSatisfy { $0.count <= $1 }
        guard done else {
            toast(L.t("quest.objectives"))
            SoundManager.shared.play("error")
            return false
        }
        // Consume collected items.
        for obj in def.objectives where obj.type == "collect" {
            removeItem(itemId: obj.target, quantity: obj.count)
        }
        session.quests[id]?.state = .turnedIn
        session.stats.questsDone += 1
        addGold(def.reward.gold)
        addXP(def.reward.xp)
        for itemId in def.reward.items {
            addItem(itemId: itemId)
        }
        if session.trackedQuest == id {
            session.trackedQuest = session.quests.values.first(where: { $0.state == .active }).map { $0.id }
            if session.trackedQuest == nil {
                session.trackedQuest = ContentDatabase.shared.quests.values
                    .first(where: { $0.kind == .main && isQuestAvailable($0) })?.id
            }
        }
        if def.reward.gold > 0 || !def.reward.items.isEmpty {
            toast("\(L.t("common.reward")): \(def.reward.gold > 0 ? "+\(def.reward.gold) \(L.t("common.gold"))" : "")")
        }
        if def.kind == .main {
            scene?.hud.banner(title: def.displayTitle, sub: L.t("hud.questDone"))
        }
        SoundManager.shared.play("questDone")
        acceptAutoQuests()
        checkAchievements(.questDone(count: session.stats.questsDone))
        return true
    }

    func trackQuest(_ id: String) {
        session.trackedQuest = id
        SoundManager.shared.play("click")
    }

    func trackedQuestTitle() -> String? {
        guard let id = session.trackedQuest,
              let def = ContentDatabase.shared.quests[id],
              let progress = session.quests[id],
              progress.state == .active || progress.state == .readyToTurnIn
        else { return nil }
        return def.displayTitle
    }

    func trackedQuestProgress() -> String? {
        guard let id = session.trackedQuest,
              let def = ContentDatabase.shared.quests[id],
              let progress = session.quests[id]
        else { return nil }
        let parts = zip(def.objectives, progress.counts).map { "\($1)/\($0.count)" }
        return parts.joined(separator: " · ")
    }

    /// NPC overhead marker based on quest involvement.
    func markerFor(npcId: String) -> String? {
        let db = ContentDatabase.shared
        var hasActive = false
        for def in db.quests.values {
            let state = session.quests[def.id]?.state
            if state == nil && isQuestAvailable(def) && def.giver == npcId {
                return "alert"
            }
            if state == .readyToTurnIn && def.turnIn == npcId {
                return "alert"
            }
            if state == .active && (def.giver == npcId || def.turnIn == npcId) {
                hasActive = true
            }
        }
        return hasActive ? "active" : nil
    }

    // MARK: - Dialogue

    func openDialogue(npcId: String) {
        guard let tree = ContentDatabase.shared.dialogues[npcId] else { return }
        questEvent(.talk(npcId: npcId))
        activeDialogue = ActiveDialogue(npcId: npcId, nodeId: tree.start)
        showDialogue = true
        SoundManager.shared.play("select")
    }

    func closeDialogue() {
        showDialogue = false
        activeDialogue = nil
        saveGame(silent: true)
    }

    func currentDialogueNode() -> DialogueNode? {
        guard let dlg = activeDialogue,
              let tree = ContentDatabase.shared.dialogues[dlg.npcId]
        else { return nil }
        return tree.nodes.first(where: { $0.id == dlg.nodeId }) ?? tree.nodes.first
    }

    func visibleChoices() -> [DialogueChoice] {
        guard let node = currentDialogueNode() else { return [] }
        var result: [DialogueChoice] = []
        for choice in node.choices {
            if let req = choice.requiresQuest, questState(req) != .active {
                continue
            }
            if let reqDone = choice.requiresQuestDone, questState(reqDone) != .turnedIn {
                continue
            }
            if let gives = choice.givesQuest {
                guard let def = ContentDatabase.shared.quests[gives], isQuestAvailable(def) else { continue }
            }
            if let turnIn = choice.turnInQuest {
                guard let state = questState(turnIn), state == .active || state == .readyToTurnIn else { continue }
            }
            if let item = choice.requiresItem, session.inventoryCount(itemId: item) == 0 {
                continue
            }
            result.append(choice)
        }
        return result
    }

    func chooseDialogue(_ choice: DialogueChoice) {
        SoundManager.shared.play("click")
        if let gives = choice.givesQuest {
            acceptQuest(gives)
        }
        if let turnIn = choice.turnInQuest {
            guard turnInQuest(turnIn) else { return }
        }
        if let item = choice.givesItem {
            addItem(itemId: item)
        }
        if let gold = choice.givesGold {
            addGold(gold)
        }
        if choice.action == "heal" {
            hp = derivedStats().maxHP
            mana = derivedStats().maxMana
            toast(L.t("dlg.healed"))
            SoundManager.shared.play("heal")
        }
        if choice.openShop == true {
            openShop(npcId: activeDialogue?.npcId ?? "")
            return
        }
        if let next = choice.next {
            activeDialogue?.nodeId = next
        } else {
            closeDialogue()
        }
    }

    // MARK: - Shop

    var shopNpcId = ""

    func openShop(npcId: String) {
        shopNpcId = npcId
        shopItems = shopStock(npcId: npcId).filter {
            !($0.stock > 0 && session.purchasedShop.contains("\(npcId):\($0.itemId)"))
        }
        showDialogue = false
        showShop = true
        SoundManager.shared.play("coin")
    }

    func closeShop() {
        showShop = false
    }

    func shopStock(npcId: String) -> [ShopItem] {
        switch npcId {
        case "merchant":
            return [
                ShopItem(itemId: "potion_minor", price: 20, stock: -1),
                ShopItem(itemId: "potion_major", price: 60, stock: -1),
                ShopItem(itemId: "mana_minor", price: 20, stock: -1),
                ShopItem(itemId: "bomb", price: 45, stock: -1),
                ShopItem(itemId: "meat", price: 10, stock: -1),
                ShopItem(itemId: "sword_steel", price: 120, stock: 1),
                ShopItem(itemId: "armor_leather", price: 80, stock: 1),
                ShopItem(itemId: "ring_copper", price: 70, stock: 1),
                ShopItem(itemId: "elixir_dawn", price: 150, stock: 2),
            ]
        case "hermit":
            return [
                ShopItem(itemId: "potion_minor", price: 22, stock: -1),
                ShopItem(itemId: "mana_minor", price: 18, stock: -1),
                ShopItem(itemId: "mana_major", price: 50, stock: -1),
                ShopItem(itemId: "bomb", price: 45, stock: -1),
                ShopItem(itemId: "bow_hunter", price: 150, stock: 1),
                ShopItem(itemId: "bow_ember", price: 450, stock: 1),
                ShopItem(itemId: "elixir_dawn", price: 150, stock: 3),
            ]
        case "guard":
            return [
                ShopItem(itemId: "potion_major", price: 60, stock: -1),
                ShopItem(itemId: "mana_major", price: 55, stock: -1),
                ShopItem(itemId: "armor_chain", price: 250, stock: 1),
                ShopItem(itemId: "sword_rune", price: 350, stock: 1),
                ShopItem(itemId: "armor_storm", price: 390, stock: 1),
            ]
        case "spirit":
            return [
                ShopItem(itemId: "potion_major", price: 60, stock: -1),
                ShopItem(itemId: "mana_major", price: 55, stock: -1),
                ShopItem(itemId: "bomb", price: 45, stock: -1),
                ShopItem(itemId: "amulet_blood", price: 450, stock: 1),
                ShopItem(itemId: "sword_frost", price: 420, stock: 1),
                ShopItem(itemId: "ring_vampire", price: 320, stock: 1),
            ]
        default:
            return [ShopItem(itemId: "potion_minor", price: 20, stock: -1)]
        }
    }

    func buyItem(_ shopItem: ShopItem) {
        guard let index = shopItems.firstIndex(where: { $0.itemId == shopItem.itemId }) else { return }
        if shopItems[index].stock == 0 { return }
        guard session.gold >= shopItem.price else {
            toast(L.t("shop.poor"))
            SoundManager.shared.play("error")
            return
        }
        addGold(-shopItem.price)
        addItem(itemId: shopItem.itemId)
        if shopItems[index].stock > 0 {
            shopItems[index].stock -= 1
            let key = "\(shopNpcId):\(shopItem.itemId)"
            if !session.purchasedShop.contains(key) { session.purchasedShop.append(key) }
        }
        questEvent(.collect(itemId: shopItem.itemId, count: session.inventoryCount(itemId: shopItem.itemId)))
        toast(L.t("shop.bought"))
        SoundManager.shared.play("coin")
        syncBadges()
    }

    // MARK: - Signs

    func showSign(text: String) {
        signText = text
        showSign = true
        SoundManager.shared.play("select")
    }

    func closeSign() {
        showSign = false
    }

    // MARK: - Prompts

    func setPrompt(_ text: String?) {
        if interactPrompt != text {
            interactPrompt = text
        }
    }

    // MARK: - Travel / death / victory

    func travelTo(levelId: String) {
        session.currentLevel = levelId
        session.checkpointId = nil
        if !session.unlockedLevels.contains(levelId) {
            session.unlockedLevels.append(levelId)
        }
        saveGame(silent: true)
        scene?.loadLevel(levelId)
    }

    func onPlayerDeath() {
        session.stats.deaths += 1
        SoundManager.shared.play("defeat")
        checkAchievements(.death(count: session.stats.deaths))
        saveGame(silent: true)
        showDeath = true
    }

    func deathPenalty() -> Int {
        Int(Double(session.gold) * AppSettings.shared.difficulty.deathPenalty)
    }

    func respawn() {
        let penalty = deathPenalty()
        addGold(-penalty)
        let derived = derivedStats()
        hp = derived.maxHP * 0.6
        mana = derived.maxMana
        if let scene {
            scene.player.position = scene.spawnPoint()
            scene.player.physicsBody?.velocity = .zero
            scene.player.invulnerable = 2.0
            scene.cameraNode.position = scene.player.position
            scene.projectiles.filter { $0.hostile }.forEach { $0.removeFromParent() }
            scene.projectiles.removeAll { $0.parent == nil }
            scene.hud.setLowHp(false)
        }
        showDeath = false
        SoundManager.shared.play("checkpoint")
    }

    func onBossDefeated(bossId: String) {
        if !session.defeatedBosses.contains(bossId) {
            session.defeatedBosses.append(bossId)
        }
        questEvent(.bossDefeated(bossId: bossId))
        checkAchievements(.boss(id: bossId))
        toast(L.t("hud.bossDown"))
        saveGame(silent: true)
        if bossId == "boss_dragon" {
            // The final seal breaks when the player enters the Rift portal.
        }
    }

    func onVictory() {
        SoundManager.shared.play("victory")
        checkAchievements(.victory)
        saveGame(silent: true)
        showVictory = true
    }

    func continueAfterVictory() {
        showVictory = false
    }

    // MARK: - Achievements

    func checkKillAchievements() {
        checkAchievements(.kill(count: session.stats.kills))
    }

    func grantComboAchievement(combo: Int) {
        if combo > 0 && combo % 10 == 0 {
            addGold(combo * 2)
            toast("+\(combo * 2) \(L.t("common.gold"))!")
        }
    }

    func checkAchievements(_ event: AchievementEvent) {
        let newly = AchievementManager.check(event, session: session)
        guard !newly.isEmpty else { return }
        session.achievements.append(contentsOf: newly)
        AchievementStore.grant(newly)
        for id in newly {
            if let def = AchievementManager.all.first(where: { $0.id == id }) {
                toast("\(L.t("ach.got")) \(def.title)")
            }
        }
        SoundManager.shared.play("questDone")
    }

    // MARK: - Character creation

    static let heroNames = [
        "Aria", "Kael", "Nyx", "Rowan", "Lyra", "Dain", "Elowen", "Fen",
        "Ария", "Каэль", "Никс", "Рован", "Лира", "Дайн", "Эловен", "Фен",
    ]

    func randomHeroName() -> String {
        Self.heroNames.randomElement() ?? "Hero"
    }

    // MARK: - NPC names / fast travel / tutorial / continue

    func npcName(_ npcId: String) -> String {
        let key = "npc.\(npcId)"
        let value = L.t(key)
        return value == key ? npcId.capitalized : value
    }

    func fastTravel(to checkpointId: String) {
        guard let scene, scene.checkpoints.contains(where: { $0.checkpointId == checkpointId }),
              let node = scene.checkpoints.first(where: { $0.checkpointId == checkpointId })
        else { return }
        session.checkpointId = checkpointId
        scene.player.position = node.position + CGPoint(x: 0, y: 40)
        scene.player.physicsBody?.velocity = .zero
        scene.player.invulnerable = 1.5
        scene.cameraNode.position = scene.player.position
        scene.puff(at: scene.player.position, big: true, color: SKColor(red: 0.7, green: 0.5, blue: 1, alpha: 1))
        SoundManager.shared.play("portal")
        saveGame(silent: true)
    }

    func sawHint(_ id: String) -> Bool {
        session.seenHints.contains(id)
    }

    func markHint(_ id: String) {
        if !session.seenHints.contains(id) { session.seenHints.append(id) }
    }

    func continueLatest() {
        var best: (slot: Int, at: Date)?
        for slot in 0..<SaveManager.slotCount where SaveManager.exists(slot: slot) {
            if let loaded = SaveManager.load(slot: slot), best == nil || loaded.savedAt > best!.at {
                best = (slot, loaded.savedAt)
            }
        }
        if let best { continueGame(slot: best.slot) }
    }
}

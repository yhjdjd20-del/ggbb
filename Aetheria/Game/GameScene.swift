import SpriteKit

/// Data for the SwiftUI minimap.
struct MinimapSnapshot {
    var levelW: CGFloat
    var levelH: CGFloat
    var solids: [CGRect]
    var player: CGPoint
    var portal: CGPoint
    var portalLocked: Bool
    var checkpoints: [CGPoint]
    var npcs: [CGPoint]
    var boss: CGPoint?
}

/// The main gameplay scene: world simulation, combat, camera, quest hooks.
final class GameScene: SKScene, SKPhysicsContactDelegate, PlayerDelegate, EnemyDelegate {
    weak var viewModel: GameViewModel?

    var level: LevelData!
    var levelId: String = "forest"

    // World content (rebuilt per level).
    let world = SKNode()
    var parallax: [(node: SKNode, factor: CGFloat)] = []
    var platforms: [SKSpriteNode] = []
    var solidRects: [CGRect] = []
    var ladders: [CGRect] = []
    var hazards: [(rect: CGRect, damage: Double, type: String)] = []
    var movingPlatforms: [MovingPlatformNode] = []
    var enemies: [EnemyNode] = []
    var npcs: [NPCNode] = []
    var chests: [ChestNode] = []
    var checkpoints: [CheckpointNode] = []
    var signs: [SignNode] = []
    var projectiles: [ProjectileNode] = []
    var pickups: [PickupNode] = []
    var portal: PortalNode?
    var boss: BossNode?
    var bossArena: CGRect?
    var bossIntroduced = false
    var barrierNodes: [SKSpriteNode] = []

    // Persistent nodes.
    var player: PlayerNode!
    let cameraNode = SKCameraNode()
    let skyNode = SKSpriteNode()
    let hud = HUDLayer()
    let weather = WeatherLayer()
    let damageLayer = DamageLayer()
    var camBounds = CGRect.zero

    // State.
    var derived: DerivedStats!
    var lastUpdate: TimeInterval = 0
    var spellCooldown = 0.0
    var combo = 0
    var comboTimer = 0.0
    var lastSafe = CGPoint.zero
    var safeTimer = 0.0
    var interactTimer = 0.0
    var minimapTimer = 0.0
    var markerTimer = 0.0
    var autosaveTimer = 0.0
    var shake = 0.0
    var lastGoldShown = -1
    var built = false

    // MARK: - Init

    init(size: CGSize, viewModel: GameViewModel, levelId: String) {
        self.viewModel = viewModel
        self.levelId = levelId
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
        addChild(world)
        camera = cameraNode
        addChild(cameraNode)
        skyNode.zPosition = -100
        cameraNode.addChild(skyNode)
        weather.setup()
        cameraNode.addChild(weather)
        damageLayer.setup()
        world.addChild(damageLayer)
        hud.setup()
        cameraNode.addChild(hud)
        fitCameraToView()
        if !built {
            built = true
            buildWorld(levelId: levelId)
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard built else { return }
        fitCameraToView()
    }

    // MARK: - Logical viewport (resolution independence)

    /// Design viewport in world units. The camera zooms so every device shows
    /// roughly this area — identical framing on iPhone SE and Pro Max.
    static let logicalSize = CGSize(width: 1280, height: 720)

    /// World units currently visible through the camera.
    func visibleSize() -> CGSize {
        let s = cameraNode.xScale
        guard s > 0.001 else { return size }
        return CGSize(width: size.width / s, height: size.height / s)
    }

    /// Zooms the camera to the logical viewport (aspect-fill: no black bars)
    /// and re-layouts all camera-attached overlays.
    func fitCameraToView() {
        guard size.width > 1, size.height > 1 else { return }
        let z = max(size.width / Self.logicalSize.width, size.height / Self.logicalSize.height)
        cameraNode.setScale(z)
        relayoutOverlays()
    }

    /// Re-layouts sky/HUD/weather for the current visible rect.
    func relayoutOverlays() {
        let vis = visibleSize()
        skyNode.size = CGSize(width: vis.width + 160, height: vis.height + 160)
        // Safe-area insets are in points; convert to world units.
        let z = max(0.001, cameraNode.xScale)
        let raw = DeviceProfile.currentSafeArea
        let inset = UIEdgeInsets(top: raw.top / z, left: raw.left / z, bottom: raw.bottom / z, right: raw.right / z)
        hud.layout(size: vis, safeArea: inset)
        weather.layout(size: vis)
        updateCamBounds()
    }

    func updateCamBounds() {
        // Level may not exist yet when fitting the camera in didMove.
        guard level != nil else {
            camBounds = .zero
            return
        }
        let vis = visibleSize()
        camBounds = CGRect(
            x: vis.width / 2 - 60,
            y: vis.height / 2 - 60,
            width: CGFloat(level.width) - vis.width + 120,
            height: CGFloat(level.height) - vis.height + 120
        )
    }

    func buildWorld(levelId: String) {
        guard let vm = viewModel else { return }
        self.levelId = levelId
        level = ContentDatabase.shared.level(id: levelId)
        derived = vm.derivedStats()
        LevelBuilder.build(scene: self, level: level, session: vm.session)
        world.addChild(damageLayer)
        updateCamBounds()

        // Player (reused across levels).
        if player == nil {
            player = PlayerNode.create(classId: vm.session.heroClass)
            player.delegate = self
        } else {
            player.removeFromParent()
            player.groundedContacts = 0
            player.grounded = false
            player.climbing = false
            player.onLadder = false
            player.dashTime = 0
            player.invulnerable = 1.0
            player.physicsBody?.velocity = .zero
            player.physicsBody?.affectedByGravity = true
        }
        let spawn = spawnPoint()
        player.position = spawn
        lastSafe = spawn
        world.addChild(player)
        cameraNode.position = spawn

        // Full heal on entering a new region feels good; checkpoints keep damage.
        if vm.session.checkpointId == nil {
            vm.hp = derived.maxHP
            vm.mana = derived.maxMana
        } else {
            vm.hp = min(vm.hp, derived.maxHP)
            vm.mana = min(vm.mana, derived.maxMana)
        }

        hud.hideBoss()
        hud.hideCombo()
        hud.setLowHp(false)
        combo = 0
        barrierNodes.forEach { $0.removeFromParent() }
        barrierNodes.removeAll()

        SoundManager.shared.playMusic(theme: level.music)
        hud.banner(title: level.displayName, sub: vm.trackedQuestTitle() ?? L.t(level.tipKey ?? "howto.goal"))
        vm.questEvent(.levelEnter(levelId: levelId))
        pushMinimap()
    }

    func loadLevel(_ id: String) {
        projectiles.forEach { $0.removeFromParent() }
        projectiles.removeAll()
        pickups.forEach { $0.removeFromParent() }
        pickups.removeAll()
        buildWorld(levelId: id)
    }

    func spawnPoint() -> CGPoint {
        guard let vm = viewModel else { return CGPoint(x: 200, y: 300) }
        if let cpId = vm.session.checkpointId,
           let cp = level.checkpoints.first(where: { $0.id == cpId }) {
            return CGPoint(x: CGFloat(cp.x), y: CGFloat(cp.y) + 80)
        }
        return CGPoint(x: CGFloat(level.spawn.x), y: CGFloat(level.spawn.y))
    }

    func refreshDerived() {
        guard let vm = viewModel else { return }
        derived = vm.derivedStats()
        vm.hp = min(vm.hp, derived.maxHP)
        vm.mana = min(vm.mana, derived.maxMana)
    }

    // MARK: - Main loop

    override func update(_ currentTime: TimeInterval) {
        guard let vm = viewModel, !vm.modalOpen else { return }
        var dt = currentTime - lastUpdate
        lastUpdate = currentTime
        if dt <= 0 || dt > 1 { dt = 1.0 / 60.0 }
        dt = min(dt, 1.0 / 30.0)

        let input = vm.input
        spellCooldown = max(0, spellCooldown - dt)
        comboTimer -= dt
        if comboTimer <= 0 && combo > 0 {
            combo = 0
            hud.hideCombo()
        }

        // Ladders.
        player.onLadder = ladders.contains { $0.insetBy(dx: -8, dy: 0).contains(player.position) }
        player.update(dt: dt, input: input, derived: derived)

        updateMovingPlatforms(dt: dt)
        updateEnemies(dt: dt)
        updateProjectiles(dt: dt)
        updatePickups(dt: dt)
        updateHazards()
        updateSafeSpot(dt: dt)
        updateFallOut()
        updateInteract(dt: dt)
        updateBoss(dt: dt)
        updateCamera(dt: dt)
        updateParallax()

        // Mana regen.
        let regen = 2.4 * (level.weather == "rain" ? 1.5 : 1.0)
        vm.mana = min(derived.maxMana, vm.mana + regen * dt)
        vm.session.stats.playTime += dt

        // HUD.
        hud.setBars(hp: vm.hp, maxHp: derived.maxHP, mana: vm.mana, maxMana: derived.maxMana,
                    xp: vm.session.xp, xpNext: CombatFormulas.xpForLevel(vm.session.level),
                    level: vm.session.level)
        if vm.session.gold != lastGoldShown {
            lastGoldShown = vm.session.gold
            hud.setGold(vm.session.gold)
        }

        // Periodic sync.
        minimapTimer -= dt
        if minimapTimer <= 0 {
            minimapTimer = 0.2
            pushMinimap()
            vm.syncBadges()
        }
        markerTimer -= dt
        if markerTimer <= 0 {
            markerTimer = 0.5
            updateMarkers()
        }
        autosaveTimer += dt
        if autosaveTimer > 60 {
            autosaveTimer = 0
            vm.saveGame(silent: true)
        }

        input.endFrame()
    }

    // MARK: - Sub-updates

    private func updateMovingPlatforms(dt: Double) {
        for platform in movingPlatforms {
            let delta = CGVector(dx: platform.position.x - platform.prevPos.x,
                                 dy: platform.position.y - platform.prevPos.y)
            platform.prevPos = platform.position
            // Carry the player when standing on top.
            let top = platform.position.y + platform.size.height / 2
            let feet = player.position.y - 33
            if abs(feet - top) < 14 && player.physicsBody?.velocity.dy ?? 0 <= 60 {
                if abs(player.position.x - platform.position.x) < platform.size.width / 2 + 14 {
                    player.position.x += delta.dx
                    player.position.y += delta.dy
                }
            }
        }
    }

    private func updateEnemies(dt: Double) {
        enemies.removeAll { $0.parent == nil }
        let snowSlow = level.weather == "snow" ? 0.95 : 1.0
        _ = snowSlow
        for enemy in enemies {
            enemy.update(dt: dt, playerPos: player.position)
        }
        if let boss, bossIntroduced, !boss.isDead {
            hud.setBossHp(boss.hp / boss.maxHp)
        }
    }

    private func updateProjectiles(dt: Double) {
        var keep: [ProjectileNode] = []
        for proj in projectiles {
            guard proj.parent != nil else { continue }
            if !proj.update(dt: dt) {
                proj.removeFromParent()
                continue
            }
            var hitWorld = false
            for rect in solidRects where rect.contains(proj.position) {
                hitWorld = true
                break
            }
            if hitWorld {
                puff(at: proj.position, big: false, color: .white)
                proj.removeFromParent()
                continue
            }
            if proj.hostile {
                if hypot(proj.position.x - player.position.x, proj.position.y - player.position.y) < 34 {
                    damagePlayer(CombatFormulas.mitigated(raw: proj.damage, defense: derived.defense), from: proj.position)
                    proj.removeFromParent()
                    continue
                }
            } else {
                var consumed = false
                for enemy in enemies where !enemy.isDead {
                    let r = enemy.touchRadius * 0.85
                    if hypot(proj.position.x - enemy.position.x, proj.position.y - enemy.position.y) < r {
                        let dmg = proj.damage * (critRoll() ? derived.critDamage : 1.0)
                        hitEnemy(enemy, damage: dmg, crit: dmg > proj.damage * 1.2, fromX: player.position.x)
                        puff(at: proj.position, big: false, color: SKColor(red: 0.5, green: 0.95, blue: 1, alpha: 1))
                        consumed = true
                        break
                    }
                }
                if consumed {
                    proj.removeFromParent()
                    continue
                }
            }
            keep.append(proj)
        }
        projectiles = keep
    }

    private func updatePickups(dt: Double) {
        guard let vm = viewModel else { return }
        var keep: [PickupNode] = []
        for pickup in pickups {
            guard pickup.parent != nil else { continue }
            pickup.life -= dt
            if pickup.life <= 0 {
                pickup.removeFromParent()
                continue
            }
            if pickup.life < 3 {
                pickup.alpha = 0.4 + 0.6 * abs(sin(pickup.life * 8))
            }
            let d = hypot(pickup.position.x - player.position.x, pickup.position.y - player.position.y)
            if d < 150 {
                let dx = (player.position.x - pickup.position.x) / max(1, d)
                let dy = (player.position.y - pickup.position.y) / max(1, d)
                pickup.vx += dx * 1400 * CGFloat(dt)
                pickup.vy += dy * 1400 * CGFloat(dt)
            } else {
                pickup.vy -= 900 * CGFloat(dt)
                pickup.vx *= 0.99
            }
            pickup.position.x += pickup.vx * CGFloat(dt)
            pickup.position.y += pickup.vy * CGFloat(dt)
            for rect in solidRects where rect.contains(pickup.position) {
                pickup.position.y = rect.maxY + 8
                pickup.vy = abs(pickup.vy) * 0.4
                pickup.vx *= 0.7
                break
            }
            if d < 38 {
                collect(pickup)
                pickup.removeFromParent()
                continue
            }
            keep.append(pickup)
        }
        pickups = keep
        _ = vm
    }

    private func updateHazards() {
        let feet = CGRect(x: player.position.x - 12, y: player.position.y - 33, width: 24, height: 30)
        for hazard in hazards {
            if feet.intersects(hazard.rect.insetBy(dx: 8, dy: 6)) {
                let hurt = damagePlayer(CombatFormulas.mitigated(raw: hazard.damage, defense: derived.defense), from: player.position + CGPoint(x: 0, y: -40))
                if hurt {
                    player.physicsBody?.velocity.dy = 480
                }
                break
            }
        }
    }

    private func updateSafeSpot(dt: Double) {
        safeTimer -= dt
        if safeTimer <= 0 {
            safeTimer = 0.5
            if player.grounded {
                lastSafe = player.position
            }
        }
    }

    private func updateFallOut() {
        if player.position.y < -140 {
            damagePlayer(25, from: player.position)
            player.position = lastSafe + CGPoint(x: 0, y: 40)
            player.physicsBody?.velocity = .zero
            player.invulnerable = max(player.invulnerable, 1.5)
        }
    }

    // MARK: - Interaction

    private func updateInteract(dt: Double) {
        guard let vm = viewModel else { return }
        interactTimer -= dt
        let target = nearestInteractable()
        if interactTimer <= 0 {
            interactTimer = 0.15
            if let target {
                vm.setPrompt(promptLabel(for: target))
            } else {
                vm.setPrompt(nil)
            }
            // Checkpoints trigger on touch.
            for cp in checkpoints where !cp.activated {
                if hypot(cp.position.x - player.position.x, cp.position.y - player.position.y) < 80 {
                    activateCheckpoint(cp)
                }
            }
        }
        if vm.input.interactQueued, let target {
            doInteract(target)
        }
    }

    private enum InteractTarget {
        case npc(NPCNode)
        case chest(ChestNode)
        case portal
        case sign(SignNode)
    }

    private func nearestInteractable() -> InteractTarget? {
        var best: (dist: CGFloat, target: InteractTarget)?
        func consider(_ point: CGPoint, radius: CGFloat, _ target: InteractTarget) {
            let d = hypot(point.x - player.position.x, point.y - player.position.y)
            if d < radius && (best == nil || d < best!.dist) {
                best = (d, target)
            }
        }
        for npc in npcs { consider(npc.position, radius: 130, .npc(npc)) }
        for chest in chests where !chest.isOpen { consider(chest.position, radius: 110, .chest(chest)) }
        if let portal { consider(portal.position, radius: 140, .portal) }
        for sign in signs { consider(sign.position, radius: 110, .sign(sign)) }
        return best?.target
    }

    private func promptLabel(for target: InteractTarget) -> String {
        switch target {
        case .npc: return L.t("hud.talk")
        case .chest: return L.t("hud.open")
        case .portal: return L.t("hud.enter")
        case .sign: return L.t("hud.read")
        }
    }

    private func doInteract(_ target: InteractTarget) {
        guard let vm = viewModel else { return }
        SoundManager.shared.play("click")
        switch target {
        case .npc(let npc):
            vm.openDialogue(npcId: npc.npcId)
        case .chest(let chest):
            guard let data = level.chests.first(where: { $0.id == chest.chestId }) else { return }
            chest.open()
            vm.openChest(chestId: chest.chestId, loot: data.loot, gold: data.gold)
            puff(at: chest.position + CGPoint(x: 0, y: 30), big: true, color: SKColor(red: 1, green: 0.85, blue: 0.35, alpha: 1))
            SoundManager.shared.play("chest")
        case .portal:
            if portal?.locked == true {
                hud.toast(L.t("hud.sealed"))
                SoundManager.shared.play("error")
            } else if level.portal.isFinal == true {
                vm.onVictory()
            } else if let targetId = level.portal.target {
                SoundManager.shared.play("portal")
                vm.travelTo(levelId: targetId)
            }
        case .sign(let sign):
            vm.showSign(text: localized(sign.text, sign.textRu))
        }
    }

    private func activateCheckpoint(_ cp: CheckpointNode) {
        guard let vm = viewModel else { return }
        cp.activate()
        vm.session.checkpointId = cp.checkpointId
        vm.healPlayer(derived.maxHP * 0.5)
        vm.restoreMana(derived.maxMana * 0.5)
        vm.questEvent(.reach(checkpointId: cp.checkpointId))
        vm.saveGame(silent: true)
        hud.toast("\(L.t("hud.checkpoint")) ✓")
        SoundManager.shared.play("checkpoint")
        Haptics.notification(.success)
    }

    // MARK: - Boss

    private func updateBoss(dt: Double) {
        _ = dt
        guard let vm = viewModel, let boss, !boss.isDead else { return }
        if !bossIntroduced, let arena = bossArena {
            if arena.contains(player.position) {
                bossIntroduced = true
                hud.showBoss(name: boss.def.displayName)
                hud.banner(title: boss.def.displayName, sub: "")
                SoundManager.shared.play("bossRoar")
                SoundManager.shared.playMusic(theme: "boss")
                showBarriers(arena: arena)
                shake = max(shake, 10)
            }
        }
        if bossIntroduced, let arena = bossArena {
            player.position.x = min(max(player.position.x, arena.minX + 40), arena.maxX - 40)
        }
        _ = vm
    }

    private func showBarriers(arena: CGRect) {
        for x in [arena.minX, arena.maxX] {
            let wall = SKSpriteNode(texture: TextureFactory.get("glow"))
            wall.size = CGSize(width: 36, height: 950)
            wall.position = CGPoint(x: x, y: 500)
            wall.colorBlendFactor = 0.7
            wall.color = SKColor(red: 1, green: 0.2, blue: 0.3, alpha: 1)
            wall.alpha = 0.7
            wall.zPosition = 6
            world.addChild(wall)
            barrierNodes.append(wall)
        }
    }

    // MARK: - Camera & parallax

    private func updateCamera(dt: Double) {
        var target = player.position + CGPoint(x: player.facing * 50, y: 60)
        if camBounds.width > 0 {
            target.x = min(max(target.x, camBounds.minX), camBounds.maxX)
        } else {
            target.x = CGFloat(level.width) / 2
        }
        if camBounds.height > 0 {
            target.y = min(max(target.y, camBounds.minY), camBounds.maxY)
        } else {
            target.y = visibleSize().height / 2
        }
        let k = min(1, CGFloat(dt) * 6)
        cameraNode.position.x += (target.x - cameraNode.position.x) * k
        cameraNode.position.y += (target.y - cameraNode.position.y) * k
        if shake > 0.2 {
            shake *= pow(0.02, CGFloat(dt))
            cameraNode.position.x += CGFloat.random(in: -shake...shake)
            cameraNode.position.y += CGFloat.random(in: -shake...shake)
        } else {
            shake = 0
        }
    }

    private func updateParallax() {
        let cam = cameraNode.position
        for layer in parallax {
            layer.node.position.x = cam.x * (1 - layer.factor)
            layer.node.position.y = cam.y * (1 - layer.factor) * 0.35
        }
    }

    func addShake(_ amount: CGFloat) {
        shake = min(26, shake + amount)
    }

    // MARK: - Physics contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA, b = contact.bodyB
        let playerBody = a.categoryBitMask == PhysicsCategory.player ? a : (b.categoryBitMask == PhysicsCategory.player ? b : nil)
        let other = playerBody === a ? b : a
        guard playerBody != nil else { return }
        let mask = other.categoryBitMask
        if mask == PhysicsCategory.ground || mask == PhysicsCategory.platform || mask == PhysicsCategory.moving {
            player.landed(contactY: contact.contactPoint.y)
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let a = contact.bodyA, b = contact.bodyB
        let isPlayer = a.categoryBitMask == PhysicsCategory.player || b.categoryBitMask == PhysicsCategory.player
        guard isPlayer else { return }
        let other = a.categoryBitMask == PhysicsCategory.player ? b : a
        let mask = other.categoryBitMask
        if mask == PhysicsCategory.ground || mask == PhysicsCategory.platform || mask == PhysicsCategory.moving {
            player.leftGround()
        }
    }

    // MARK: - PlayerDelegate

    func playerDidJump(doubleJump: Bool) {
        guard let vm = viewModel else { return }
        vm.session.stats.jumps += 1
        SoundManager.shared.play(doubleJump ? "doubleJump" : "jump")
        if doubleJump {
            puff(at: player.position + CGPoint(x: 0, y: -30), big: false, color: .white)
        }
    }

    func playerDidLand(fallSpeed: CGFloat) {
        if fallSpeed < -900 {
            SoundManager.shared.play("land")
            puff(at: player.position + CGPoint(x: 0, y: -30), big: false, color: SKColor(white: 1, alpha: 0.7))
        }
    }

    func playerDidDash(direction: CGFloat) {
        _ = direction
        viewModel?.session.stats.dashes += 1
        SoundManager.shared.play("dash")
        Haptics.impact(.light)
        let ghost = SKSpriteNode(texture: player.texture)
        ghost.position = player.position
        ghost.xScale = player.xScale
        ghost.zPosition = 9
        ghost.alpha = 0.5
        ghost.colorBlendFactor = 0.6
        ghost.color = SKColor(red: 0.5, green: 0.85, blue: 1, alpha: 1)
        world.addChild(ghost)
        ghost.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
    }

    func playerDidAttack(combo: Int) {
        SoundManager.shared.play("swing")
        let slash = SKSpriteNode(texture: TextureFactory.get("slash_\(combo % 3)"))
        slash.position = player.position + CGPoint(x: player.facing * 55, y: 5)
        slash.xScale = player.facing
        slash.zPosition = 11
        world.addChild(slash)
        slash.run(SKAction.sequence([
            SKAction.group([SKAction.fadeOut(withDuration: 0.18), SKAction.scale(to: 1.25, duration: 0.18)]),
            SKAction.removeFromParent(),
        ]))
        performMeleeHit(combo: combo)
    }

    func playerDidCast() {
        guard let vm = viewModel else { return }
        if spellCooldown > 0 { return }
        let cost = 12.0 * derived.spellCostMultiplier
        if vm.mana < cost {
            hud.toast(L.t("hud.noMana"))
            SoundManager.shared.play("error")
            return
        }
        spellCooldown = 0.35
        vm.mana -= cost
        let (damage, _) = CombatFormulas.spellDamage(derived: derived)
        let bolt = ProjectileNode.create(kind: "bolt", hostile: false)
        bolt.position = player.position + CGPoint(x: player.facing * 40, y: 10)
        bolt.velocity = aimVelocity(from: bolt.position, speed: 640)
        bolt.damage = damage
        bolt.life = 2.4
        world.addChild(bolt)
        projectiles.append(bolt)
        SoundManager.shared.play("shoot")
    }

    /// Bolt aim assist: fires at the nearest living enemy in the facing
    /// half-plane (so hovering bosses stay hittable for melee classes),
    /// flat otherwise.
    private func aimVelocity(from origin: CGPoint, speed: CGFloat) -> CGVector {
        var best: EnemyNode?
        var bestDist: CGFloat = 560
        for enemy in enemies where !enemy.isDead {
            let dx = enemy.position.x - origin.x
            guard dx * player.facing >= 0 else { continue }
            let d = hypot(dx, enemy.position.y - origin.y)
            if d < bestDist {
                bestDist = d
                best = enemy
            }
        }
        guard let target = best, bestDist > 1 else {
            return CGVector(dx: player.facing * speed, dy: 40)
        }
        let dx = target.position.x - origin.x
        let dy = target.position.y - origin.y
        let len = max(1, hypot(dx, dy))
        return CGVector(dx: dx / len * speed, dy: dy / len * speed)
    }

    // MARK: - Melee & damage

    private func performMeleeHit(combo: Int) {
        guard let vm = viewModel else { return }
        let (damage, crit) = CombatFormulas.meleeDamage(derived: derived, comboIndex: combo)
        let range: CGFloat = 105
        var hitAny = false
        for enemy in enemies where !enemy.isDead {
            let dx = enemy.position.x - player.position.x
            let dy = enemy.position.y - player.position.y
            if abs(dy) < 90 && ((dx * player.facing > 0 && abs(dx) < range) || abs(dx) < 46) {
                hitEnemy(enemy, damage: damage, crit: crit, fromX: player.position.x)
                hitAny = true
            }
        }
        // Sword can swat hostile projectiles out of the air.
        for proj in projectiles where proj.hostile {
            if hypot(proj.position.x - player.position.x, proj.position.y - player.position.y) < range {
                puff(at: proj.position, big: false, color: .white)
                proj.removeFromParent()
            }
        }
        projectiles.removeAll { $0.parent == nil }
        if hitAny {
            self.combo += 1
            comboTimer = 2.2
            hud.showCombo(self.combo)
            if self.combo >= 10 {
                vm.grantComboAchievement(combo: self.combo)
            }
        }
        _ = vm
    }

    private func critRoll() -> Bool {
        Double.random(in: 0...1) < derived.critChance
    }

    private func hitEnemy(_ enemy: EnemyNode, damage: Double, crit: Bool, fromX: CGFloat) {
        guard let vm = viewModel else { return }
        let dir: CGFloat = enemy.position.x >= fromX ? 1 : -1
        let killed = enemy.takeDamage(damage, crit: crit, fromDir: dir)
        vm.session.stats.damageDealt += damage
        damageLayer.spawn(text: "\(Int(damage))", at: enemy.position + CGPoint(x: 0, y: enemy.size.height / 2),
                          color: crit ? SKColor(red: 1, green: 0.75, blue: 0.2, alpha: 1) : .white, big: crit)
        if derived.lifesteal > 0 {
            vm.healPlayer(damage * derived.lifesteal)
        }
        if crit {
            addShake(5)
            SoundManager.shared.play("crit")
            Haptics.impact(.medium)
        } else {
            SoundManager.shared.play("hit")
            Haptics.impact(.light)
        }
        _ = killed
    }

    /// Damages the player; returns true if the hit connected.
    @discardableResult
    func damagePlayer(_ amount: Double, from: CGPoint) -> Bool {
        guard let vm = viewModel, vm.hp > 0 else { return false }
        let dir: CGFloat = player.position.x >= from.x ? 1 : -1
        guard player.takeHit(knockback: dir) else { return false }
        vm.hp -= amount
        vm.session.stats.damageTaken += amount
        damageLayer.spawn(text: "-\(Int(amount))", at: player.position + CGPoint(x: 0, y: 50),
                          color: SKColor(red: 1, green: 0.35, blue: 0.35, alpha: 1), big: false)
        addShake(7)
        SoundManager.shared.play("hurt")
        Haptics.notification(.error)
        hud.setLowHp(vm.hp < derived.maxHP * 0.3)
        if vm.hp <= 0 {
            vm.hp = 0
            vm.onPlayerDeath()
        }
        return true
    }

    // MARK: - EnemyDelegate

    func enemyShoot(from: CGPoint, velocity: CGVector, damage: Double, kind: String) {
        let proj = ProjectileNode.create(kind: kind, hostile: true)
        proj.position = from
        proj.velocity = velocity
        proj.damage = damage
        if kind == "rock" { proj.gravity = 900 }
        proj.life = 5
        world.addChild(proj)
        projectiles.append(proj)
        SoundManager.shared.play("shoot")
    }

    func enemyDealTouchDamage(_ enemy: EnemyNode, amount: Double) {
        damagePlayer(CombatFormulas.mitigated(raw: amount, defense: derived.defense), from: enemy.position)
    }

    func enemyAoE(at point: CGPoint, radius: CGFloat, damage: Double) {
        explode(at: point, radius: radius)
        if hypot(player.position.x - point.x, player.position.y - point.y) < radius {
            damagePlayer(CombatFormulas.mitigated(raw: damage, defense: derived.defense), from: point)
        }
    }

    func enemyTelegraphCircle(at point: CGPoint, radius: CGFloat, duration: Double) {
        let node = SKSpriteNode(texture: TextureFactory.get("glow"))
        node.size = CGSize(width: radius * 2, height: radius * 2)
        node.position = point
        node.colorBlendFactor = 0.7
        node.color = SKColor(red: 1, green: 0.15, blue: 0.15, alpha: 1)
        node.alpha = 0.55
        node.zPosition = 6
        world.addChild(node)
        node.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.85, duration: duration),
            SKAction.removeFromParent(),
        ]))
    }

    func enemyTelegraphRect(_ rect: CGRect, duration: Double) {
        let node = SKSpriteNode(texture: TextureFactory.get("telegraph"))
        node.size = rect.size
        node.position = CGPoint(x: rect.midX, y: rect.midY)
        node.zPosition = 6
        world.addChild(node)
        node.run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.removeFromParent(),
        ]))
    }

    func enemySummon(type: String, at point: CGPoint) {
        guard let def = ContentDatabase.shared.enemies[type] else { return }
        let diff = AppSettings.shared.difficulty
        let enemy = EnemyNode.create(def: def)
        enemy.delegate = self
        enemy.maxHp = def.hp * diff.enemyHP
        enemy.hp = enemy.maxHp
        enemy.damageMul = diff.enemyDamage
        enemy.position = point
        enemy.anchor = point
        enemy.active = true
        enemy.setScale(0.1)
        world.addChild(enemy)
        enemies.append(enemy)
        enemy.run(SKAction.scale(to: CGFloat(def.scale), duration: 0.3))
        puff(at: point, big: true, color: SKColor(red: 0.7, green: 0.4, blue: 1, alpha: 1))
    }

    func enemyPuff(at point: CGPoint, big: Bool) {
        puff(at: point, big: big, color: SKColor(white: 0.9, alpha: 1))
    }

    func enemyDied(_ enemy: EnemyNode) {
        guard let vm = viewModel else { return }
        let pos = enemy.position
        SoundManager.shared.play("enemyDie")
        puff(at: pos, big: enemy.isBoss, color: SKColor(red: 1, green: 0.6, blue: 0.3, alpha: 1))
        if enemy.isBoss {
            explode(at: pos, radius: 160)
            addShake(20)
        }

        // Rewards.
        let xp = CombatFormulas.xpReward(base: enemy.def.xp, level: vm.session.level, bonus: derived.xpBonus)
        let weatherXPMult = level.weather == "ash" ? 1.05 : 1.0
        vm.addXP(Int(Double(xp) * weatherXPMult))
        let goldBonus = 1.0 + derived.goldBonus + (level.weather == "leaves" ? 0.05 : 0)
        let gold = Int(Double(Int.random(in: enemy.def.goldMin...max(enemy.def.goldMin, enemy.def.goldMax))) * goldBonus)
        spawnCoins(amount: gold, at: pos)
        for loot in enemy.def.loot {
            if Double.random(in: 0...1) < loot.chance {
                let qty = Int.random(in: loot.min...max(loot.min, loot.max))
                spawnPickup(kind: .item(itemId: loot.item, quantity: qty), at: pos)
            }
        }
        if Double.random(in: 0...1) < 0.1 && vm.hp < derived.maxHP * 0.7 {
            spawnPickup(kind: .heart(amount: 22), at: pos)
        }
        if Double.random(in: 0...1) < 0.08 {
            spawnPickup(kind: .mana(amount: 22), at: pos)
        }

        vm.session.stats.kills += 1
        if enemy.isBoss {
            vm.session.stats.bossesKilled += 1
            vm.onBossDefeated(bossId: enemy.def.id)
            hud.hideBoss()
            barrierNodes.forEach { $0.removeFromParent() }
            barrierNodes.removeAll()
            portal?.setLocked(false)
            boss = nil
            SoundManager.shared.playMusic(theme: level.music)
        } else {
            vm.questEvent(.kill(enemyId: enemy.def.id))
        }
        vm.checkKillAchievements()

        enemy.run(SKAction.sequence([
            SKAction.group([SKAction.fadeOut(withDuration: 0.3), SKAction.scale(to: 0.2, duration: 0.3)]),
            SKAction.removeFromParent(),
        ]))
    }

    // MARK: - Pickups & effects

    func spawnCoins(amount: Int, at pos: CGPoint) {
        var left = amount
        while left > 0 {
            let chunk = min(left, 25)
            left -= chunk
            spawnPickup(kind: .coin(amount: chunk), at: pos)
            if pickups.count > 60 { break }
        }
    }

    func spawnPickup(kind: PickupKind, at pos: CGPoint) {
        let pickup = PickupNode.create(kind: kind)
        pickup.position = pos + CGPoint(x: CGFloat.random(in: -20...20), y: 20)
        world.addChild(pickup)
        pickups.append(pickup)
    }

    private func collect(_ pickup: PickupNode) {
        guard let vm = viewModel else { return }
        switch pickup.kind {
        case .coin(let amount):
            vm.addGold(amount)
            SoundManager.shared.play("coin")
        case .heart(let amount):
            vm.healPlayer(amount)
            damageLayer.spawn(text: "+\(Int(amount))", at: player.position + CGPoint(x: 0, y: 50),
                              color: SKColor(red: 0.4, green: 1, blue: 0.5, alpha: 1), big: false)
            SoundManager.shared.play("pickup")
        case .mana(let amount):
            vm.restoreMana(amount)
            damageLayer.spawn(text: "+\(Int(amount))", at: player.position + CGPoint(x: 0, y: 50),
                              color: SKColor(red: 0.4, green: 0.7, blue: 1, alpha: 1), big: false)
            SoundManager.shared.play("pickup")
        case .item(let itemId, let quantity):
            vm.addItem(itemId: itemId, quantity: quantity)
            if let def = ContentDatabase.shared.items[itemId] {
                hud.toast("\(L.t("toast.item")): \(def.displayName)\(quantity > 1 ? " ×\(quantity)" : "")")
            }
            vm.questEvent(.collect(itemId: itemId, count: vm.session.inventoryCount(itemId: itemId)))
            SoundManager.shared.play("pickup")
        }
    }

    func puff(at pos: CGPoint, big: Bool, color: SKColor) {
        guard AppSettings.shared.richEffects || big else { return }
        let n = big ? 8 : 4
        for _ in 0..<n {
            let sprite = SKSpriteNode(texture: TextureFactory.get("puff_\(Int.random(in: 0...1))"))
            sprite.position = pos + CGPoint(x: CGFloat.random(in: -16...16), y: CGFloat.random(in: -16...16))
            sprite.colorBlendFactor = 0.5
            sprite.color = color
            sprite.zPosition = 12
            sprite.setScale(big ? 1.6 : 1.0)
            world.addChild(sprite)
            sprite.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -60...60), y: CGFloat.random(in: 10...70), duration: 0.5),
                    SKAction.scale(to: big ? 2.6 : 1.7, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5),
                ]),
                SKAction.removeFromParent(),
            ]))
        }
    }

    func explode(at point: CGPoint, radius: CGFloat) {
        SoundManager.shared.play("explosion")
        addShake(12)
        let boom = SKSpriteNode(texture: TextureFactory.get("boom_0"))
        boom.position = point
        boom.setScale(radius / 52)
        boom.zPosition = 12
        world.addChild(boom)
        boom.run(SKAction.sequence([
            SKAction.animate(with: [TextureFactory.get("boom_0"), TextureFactory.get("boom_1"),
                                   TextureFactory.get("boom_2"), TextureFactory.get("boom_3")], timePerFrame: 0.09),
            SKAction.removeFromParent(),
        ]))
        puff(at: point, big: true, color: SKColor(red: 1, green: 0.6, blue: 0.25, alpha: 1))
    }

    /// Player-used fire bomb.
    func castBomb() {
        guard let vm = viewModel else { return }
        let radius: CGFloat = 260
        explode(at: player.position, radius: radius)
        for enemy in enemies where !enemy.isDead {
            if hypot(enemy.position.x - player.position.x, enemy.position.y - player.position.y) < radius {
                hitEnemy(enemy, damage: 90 + derived.magicPower * 0.5, crit: false, fromX: player.position.x)
            }
        }
        _ = vm
    }

    func onLevelUp() {
        SoundManager.shared.play("levelup")
        hud.toast("\(L.t("hud.levelUp")) (+1 skill, +2 attr)")
        Haptics.notification(.success)
        puff(at: player.position, big: true, color: SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1))
        let ring = SKSpriteNode(texture: TextureFactory.get("glow"))
        ring.position = player.position
        ring.colorBlendFactor = 0.6
        ring.color = SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1)
        ring.zPosition = 12
        world.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 4.5, duration: 0.5), SKAction.fadeOut(withDuration: 0.5)]),
            SKAction.removeFromParent(),
        ]))
        refreshDerived()
        viewModel?.healPlayer(derived.maxHP * 0.3)
    }

    // MARK: - Markers & minimap

    private func updateMarkers() {
        guard let vm = viewModel else { return }
        for npc in npcs {
            npc.setMarker(vm.markerFor(npcId: npc.npcId))
        }
    }

    private func pushMinimap() {
        guard let vm = viewModel else { return }
        vm.minimap = MinimapSnapshot(
            levelW: CGFloat(level.width),
            levelH: CGFloat(level.height),
            solids: solidRects,
            player: player.position,
            portal: portal?.position ?? .zero,
            portalLocked: portal?.locked ?? true,
            checkpoints: checkpoints.map { $0.position },
            npcs: npcs.map { $0.position },
            boss: boss?.position
        )
    }
}

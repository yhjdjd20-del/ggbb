import SpriteKit

/// Builds the visible/interactive world from LevelData + session state.
enum LevelBuilder {
    static func build(scene: GameScene, level: LevelData, session: GameSession) {
        scene.world.removeAllChildren()
        scene.parallax.removeAll()
        scene.platforms.removeAll()
        scene.solidRects.removeAll()
        scene.ladders.removeAll()
        scene.hazards.removeAll()
        scene.movingPlatforms.removeAll()
        scene.enemies.removeAll()
        scene.npcs.removeAll()
        scene.chests.removeAll()
        scene.checkpoints.removeAll()
        scene.signs.removeAll()
        scene.projectiles.removeAll()
        scene.pickups.removeAll()
        scene.portal = nil
        scene.boss = nil
        scene.bossArena = nil

        scene.physicsWorld.gravity = CGVector(dx: 0, dy: -2300)
        scene.physicsWorld.contactDelegate = scene

        buildSky(scene: scene, level: level)
        buildParallax(scene: scene, level: level)
        buildPlatforms(scene: scene, level: level)
        buildMovingPlatforms(scene: scene, level: level)
        buildLadders(scene: scene, level: level)
        buildHazards(scene: scene, level: level)
        buildEnemies(scene: scene, level: level)
        buildNPCs(scene: scene, level: level)
        buildChests(scene: scene, level: level, session: session)
        buildCheckpoints(scene: scene, level: level, session: session)
        buildSigns(scene: scene, level: level)
        buildPortal(scene: scene, level: level, session: session)
        buildBoss(scene: scene, level: level, session: session)
        buildDecorations(scene: scene, level: level)

        // NOTE: camBounds is recomputed by updateCamBounds() after build; the visible
        // rect (not scene.size) is the source of truth on all aspects.
        scene.weather.configure(weather: level.weather, timeOfDay: level.timeOfDay, size: scene.visibleSize())
    }

    // MARK: - Pieces

    private static func buildSky(scene: GameScene, level: LevelData) {
        scene.skyNode.texture = TextureFactory.get("sky_\(level.theme)_\(TextureFactory.skyBucket(for: level.timeOfDay))")
        let vis = scene.visibleSize()
        scene.skyNode.size = CGSize(width: vis.width + 160, height: vis.height + 160)
    }

    private static func buildParallax(scene: GameScene, level: LevelData) {
        let factors: [CGFloat] = [0.12, 0.3, 0.55]
        for layer in 0..<3 {
            let node = SKNode()
            node.zPosition = CGFloat(-90 + layer)
            let tex = TextureFactory.get("par_\(level.theme)_\(layer)")
            let count = Int(ceil(CGFloat(level.width) / 512)) + 2
            for i in 0..<count {
                let sprite = SKSpriteNode(texture: tex)
                sprite.position = CGPoint(x: CGFloat(i) * 512 + 256, y: 200)
                sprite.zPosition = CGFloat(-90 + layer)
                node.addChild(sprite)
            }
            scene.world.addChild(node)
            scene.parallax.append((node: node, factor: factors[layer]))
        }
    }

    private static func buildPlatforms(scene: GameScene, level: LevelData) {
        for p in level.platforms {
            let w = CGFloat(p.w), h = CGFloat(p.h)
            let cx = CGFloat(p.x) + w / 2, cy = CGFloat(p.y) + h / 2
            let tileKey: String
            switch p.type ?? "grass" {
            case "dirt": tileKey = "tile_dirt"
            case "stone": tileKey = "tile_stone"
            case "cave": tileKey = "tile_cave"
            case "castle": tileKey = "tile_castle"
            case "cloud": tileKey = "tile_cloud"
            case "wood": tileKey = "tile_wood"
            default: tileKey = "tile_grass"
            }
            let node = SKSpriteNode(texture: TextureFactory.get(tileKey))
            node.size = CGSize(width: w, height: h)
            node.centerRect = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
            node.position = CGPoint(x: cx, y: cy)
            node.zPosition = 4
            let body = SKPhysicsBody(rectangleOf: CGSize(width: w, height: h))
            let isGround = h >= 100 || p.y <= 0.5
            body.categoryBitMask = isGround ? PhysicsCategory.ground : PhysicsCategory.platform
            body.collisionBitMask = PhysicsCategory.none
            body.contactTestBitMask = PhysicsCategory.none
            body.isDynamic = false
            body.friction = 1.0
            node.physicsBody = body
            scene.world.addChild(node)
            scene.platforms.append(node)
            scene.solidRects.append(CGRect(x: CGFloat(p.x), y: CGFloat(p.y), width: w, height: h))
        }
    }

    private static func buildMovingPlatforms(scene: GameScene, level: LevelData) {
        for m in level.movingPlatforms {
            let node = MovingPlatformNode.create(
                w: CGFloat(m.w), h: CGFloat(m.h),
                dx: CGFloat(m.dx), dy: CGFloat(m.dy), period: m.period, theme: level.theme)
            node.position = CGPoint(x: CGFloat(m.x) + CGFloat(m.w) / 2, y: CGFloat(m.y) + CGFloat(m.h) / 2)
            node.home = node.position
            node.prevPos = node.position
            scene.world.addChild(node)
            scene.movingPlatforms.append(node)
        }
    }

    private static func buildLadders(scene: GameScene, level: LevelData) {
        for l in level.ladders {
            let node = SKSpriteNode(texture: TextureFactory.get("ladder"))
            node.size = CGSize(width: CGFloat(l.w), height: CGFloat(l.h))
            node.centerRect = CGRect(x: 0.2, y: 0.4, width: 0.6, height: 0.2)
            node.position = CGPoint(x: CGFloat(l.x) + CGFloat(l.w) / 2, y: CGFloat(l.y) + CGFloat(l.h) / 2)
            node.zPosition = 3
            scene.world.addChild(node)
            scene.ladders.append(CGRect(x: CGFloat(l.x), y: CGFloat(l.y), width: CGFloat(l.w), height: CGFloat(l.h)))
        }
    }

    private static func buildHazards(scene: GameScene, level: LevelData) {
        for hz in level.hazards {
            let rect = CGRect(x: CGFloat(hz.x), y: CGFloat(hz.y), width: CGFloat(hz.w), height: CGFloat(hz.h))
            scene.hazards.append((rect: rect, damage: hz.damage, type: hz.type))
            let count = max(1, Int(hz.w / 64))
            for i in 0..<count {
                let key = hz.type == "lava" ? "lava_0" : "spikes"
                let sprite = SKSpriteNode(texture: TextureFactory.get(key))
                sprite.position = CGPoint(x: CGFloat(hz.x) + CGFloat(i) * 64 + 32, y: CGFloat(hz.y) + CGFloat(hz.h) / 2)
                sprite.zPosition = 5
                if hz.type == "lava" {
                    sprite.run(SKAction.repeatForever(SKAction.animate(
                        with: [TextureFactory.get("lava_0"), TextureFactory.get("lava_1")], timePerFrame: 0.25)))
                }
                scene.world.addChild(sprite)
            }
        }
    }

    private static func buildEnemies(scene: GameScene, level: LevelData) {
        let db = ContentDatabase.shared
        let diff = AppSettings.shared.difficulty
        for spawn in level.enemySpawns {
            guard let def = db.enemies[spawn.id] else { continue }
            let enemy = EnemyNode.create(def: def)
            enemy.delegate = scene
            enemy.maxHp = def.hp * diff.enemyHP
            enemy.hp = enemy.maxHp
            enemy.damageMul = diff.enemyDamage
            if Double.random(in: 0...1) < 0.08 { enemy.makeElite() }
            if def.flying || def.behavior == "ghost" {
                enemy.position = CGPoint(x: CGFloat(spawn.x), y: CGFloat(spawn.y))
            } else {
                enemy.position = CGPoint(x: CGFloat(spawn.x), y: CGFloat(spawn.y) + 60)
            }
            enemy.anchor = enemy.position
            scene.world.addChild(enemy)
            scene.enemies.append(enemy)
        }
    }

    private static func buildNPCs(scene: GameScene, level: LevelData) {
        for spawn in level.npcs {
            let npc = NPCNode.create(npcId: spawn.id)
            npc.position = CGPoint(x: CGFloat(spawn.x), y: CGFloat(spawn.y) + npc.size.height / 2 - 4)
            scene.world.addChild(npc)
            scene.npcs.append(npc)
        }
    }

    private static func buildChests(scene: GameScene, level: LevelData, session: GameSession) {
        for chest in level.chests {
            let opened = session.openedChests.contains(chest.id)
            let node = ChestNode.create(chestId: chest.id, opened: opened)
            node.position = CGPoint(x: CGFloat(chest.x), y: CGFloat(chest.y) + 28)
            scene.world.addChild(node)
            scene.chests.append(node)
        }
    }

    private static func buildCheckpoints(scene: GameScene, level: LevelData, session: GameSession) {
        for cp in level.checkpoints {
            let node = CheckpointNode.create(checkpointId: cp.id, activated: session.checkpointId == cp.id)
            node.position = CGPoint(x: CGFloat(cp.x), y: CGFloat(cp.y) + 50)
            scene.world.addChild(node)
            scene.checkpoints.append(node)
        }
    }

    private static func buildSigns(scene: GameScene, level: LevelData) {
        for sign in level.signs {
            let node = SignNode.create(text: sign.text, textRu: sign.textRu)
            node.position = CGPoint(x: CGFloat(sign.x), y: CGFloat(sign.y) + 32)
            scene.world.addChild(node)
            scene.signs.append(node)
        }
    }

    private static func buildPortal(scene: GameScene, level: LevelData, session: GameSession) {
        let p = level.portal
        var locked = false
        if let bossId = p.lockedByBoss, !session.defeatedBosses.contains(bossId) {
            locked = true
        }
        let node = PortalNode.create(locked: locked)
        node.position = CGPoint(x: CGFloat(p.x), y: CGFloat(p.y) + 70)
        scene.world.addChild(node)
        scene.portal = node
    }

    private static func buildBoss(scene: GameScene, level: LevelData, session: GameSession) {
        guard let bossData = level.boss else { return }
        if session.defeatedBosses.contains(bossData.id) { return }
        guard let def = ContentDatabase.shared.enemies[bossData.id] else { return }
        let diff = AppSettings.shared.difficulty
        let boss = BossNode.createBoss(def: def)
        boss.delegate = scene
        boss.maxHp = def.hp * diff.enemyHP
        boss.hp = boss.maxHp
        boss.damageMul = diff.enemyDamage
        boss.position = CGPoint(x: CGFloat(bossData.x), y: CGFloat(bossData.y))
        boss.anchor = boss.position
        boss.baseY = boss.position.y
        scene.world.addChild(boss)
        scene.enemies.append(boss)
        scene.boss = boss
        if let ax = bossData.arenaX, let aw = bossData.arenaW {
            scene.bossArena = CGRect(x: CGFloat(ax), y: 0, width: CGFloat(aw), height: 1100)
        }
        scene.bossIntroduced = false
    }

    // MARK: - Decorations (deterministic scatter)

    private struct LCG {
        var state: UInt64
        mutating func next(_ upper: Int) -> Int {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return Int((state >> 33) % UInt64(max(1, upper)))
        }
    }

    private static func buildDecorations(scene: GameScene, level: LevelData) {
        let stableSeed = level.id.utf8.reduce(UInt64(0)) { $0 &* 31 &+ UInt64($1) }
        var rng = LCG(state: stableSeed &+ 0x9E3779B9)
        var seed: [String]
        switch level.theme {
        case "caves": seed = ["crystal", "mushroom", "mushroom", "rockDeco", "torch"]
        case "castle": seed = ["banner", "pillar", "torch", "tuft", "rockDeco"]
        case "sky": seed = ["cloudDeco", "pillar", "tuft", "crystal", "tuft"]
        default: seed = ["tree", "bush", "tuft", "tuft", "rockDeco", "torch", "bush"]
        }
        var x: CGFloat = 140
        while x < CGFloat(level.width) - 100 {
            let kind = seed[rng.next(seed.count)]
            let top = groundTop(at: x, level: level)
            if top > 0 {
                let sprite = SKSpriteNode(texture: TextureFactory.get(kind == "torch" ? "torch_0" : kind))
                sprite.position = CGPoint(x: x, y: top + sprite.size.height / 2 - 8)
                sprite.zPosition = kind == "cloudDeco" ? -80 : 2
                if kind == "cloudDeco" {
                    sprite.position.y = top + CGFloat(300 + rng.next(350))
                    sprite.alpha = 0.9
                }
                scene.world.addChild(sprite)
                if kind == "torch" {
                    sprite.run(SKAction.repeatForever(SKAction.animate(
                        with: [TextureFactory.get("torch_0"), TextureFactory.get("torch_1")], timePerFrame: 0.18)))
                    let glow = SKSpriteNode(texture: TextureFactory.get("glow"))
                    glow.position = CGPoint(x: 0, y: 34)
                    glow.setScale(1.6)
                    glow.alpha = 0.45
                    glow.colorBlendFactor = 0.6
                    glow.color = SKColor(red: 1, green: 0.7, blue: 0.3, alpha: 1)
                    sprite.addChild(glow)
                    glow.run(SKAction.repeatForever(SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.3, duration: 0.4),
                        SKAction.fadeAlpha(to: 0.55, duration: 0.4),
                    ])))
                }
            }
            x += CGFloat(230 + rng.next(260))
        }
    }

    static func groundTop(at x: CGFloat, level: LevelData) -> CGFloat {
        var top: CGFloat = 0
        for p in level.platforms where p.y <= 0.5 {
            if CGFloat(p.x) <= x && x <= CGFloat(p.x + p.w) {
                top = max(top, CGFloat(p.y + p.h))
            }
        }
        return top
    }
}

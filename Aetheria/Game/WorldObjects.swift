import SpriteKit

// MARK: - Projectiles (manual movement, manual collision in GameScene)

final class ProjectileNode: SKSpriteNode {
    var velocity = CGVector.zero
    var gravity: CGFloat = 0
    var damage = 10.0
    var hostile = true
    var life = 4.0
    var kind = "arrow"

    static func create(kind: String, hostile: Bool) -> ProjectileNode {
        let texKey: String
        switch kind {
        case "arrow_red": texKey = "arrow_red"
        case "fireball": texKey = "fireball_0"
        case "bolt": texKey = "bolt"
        case "arcane": texKey = "bolt"
        case "bone": texKey = "bone"
        case "slimeball": texKey = "slimeball"
        case "rock": texKey = "rock"
        case "wave": texKey = "slash_0"
        default: texKey = "arrow"
        }
        let node = ProjectileNode(texture: TextureFactory.get(texKey))
        node.kind = kind
        node.hostile = hostile
        node.zPosition = 8
        if kind == "fireball" {
            node.run(SKAction.repeatForever(SKAction.animate(
                with: [TextureFactory.get("fireball_0"), TextureFactory.get("fireball_1")],
                timePerFrame: 0.12)))
        }
        if kind == "bolt" || kind == "arcane" || kind == "fireball" || kind == "slimeball" {
            // Cheap magic glow: one cached tinted sprite, no per-frame cost.
            let glow = SKSpriteNode(texture: TextureFactory.get("glow"))
            glow.colorBlendFactor = 1.0
            glow.color = kind == "bolt" ? SKColor(red: 0.5, green: 0.95, blue: 1, alpha: 1)
                : kind == "arcane" ? SKColor(red: 0.75, green: 0.4, blue: 1, alpha: 1)
                : kind == "fireball" ? SKColor(red: 1, green: 0.6, blue: 0.25, alpha: 1)
                : SKColor(red: 0.5, green: 1, blue: 0.4, alpha: 1)
            glow.alpha = 0.55
            glow.setScale(0.9)
            glow.zPosition = -1
            node.addChild(glow)
        }
        return node
    }

    /// Advances the projectile; returns false when its lifetime expired.
    func update(dt: Double) -> Bool {
        velocity.dy -= gravity * CGFloat(dt)
        position.x += velocity.dx * CGFloat(dt)
        position.y += velocity.dy * CGFloat(dt)
        if kind == "arrow" || kind == "arrow_red" || kind == "bone" {
            zRotation = atan2(velocity.dy, velocity.dx)
        } else if kind == "rock" || kind == "wave" {
            zRotation += dt * 6
        }
        life -= dt
        return life > 0
    }
}

// MARK: - Pickups

enum PickupKind {
    case coin(amount: Int)
    case heart(amount: Double)
    case mana(amount: Double)
    case item(itemId: String, quantity: Int)
}

final class PickupNode: SKSpriteNode {
    var kind: PickupKind = .coin(amount: 1)
    var vx: CGFloat = 0
    var vy: CGFloat = 0
    var life = 25.0
    var magnet = false

    static func create(kind: PickupKind) -> PickupNode {
        let node: PickupNode
        switch kind {
        case .coin:
            node = PickupNode(texture: TextureFactory.get("coin_0"))
            node.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scaleX(to: 0.3, duration: 0.3), SKAction.scaleX(to: 1, duration: 0.3),
            ])))
        case .heart:
            node = PickupNode(texture: TextureFactory.get("heart"))
        case .mana:
            node = PickupNode(texture: TextureFactory.get("mana"))
        case .item:
            node = PickupNode(texture: TextureFactory.get("itemGlow"))
            node.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.4), SKAction.scale(to: 0.9, duration: 0.4),
            ])))
        }
        node.kind = kind
        node.zPosition = 7
        node.vx = CGFloat.random(in: -140...140)
        node.vy = CGFloat.random(in: 120...300)
        return node
    }
}

// MARK: - NPC

final class NPCNode: SKSpriteNode {
    var npcId = ""
    private var marker: SKLabelNode?

    static func create(npcId: String) -> NPCNode {
        let node = NPCNode(texture: TextureFactory.get("npc_\(npcId)"))
        node.npcId = npcId
        node.zPosition = 9
        node.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 1.2),
            SKAction.moveBy(x: 0, y: -4, duration: 1.2),
        ])))
        let marker = SKLabelNode(fontNamed: "Helvetica-Bold")
        marker.fontSize = 30
        marker.position = CGPoint(x: 0, y: node.size.height / 2 + 18)
        marker.zPosition = 6
        node.addChild(marker)
        node.marker = marker
        return node
    }

    /// Quest marker: "!" when a quest is available/ready, "?" when in progress.
    func setMarker(_ style: String?) {
        guard let marker else { return }
        switch style {
        case "alert":
            marker.text = "!"
            marker.fontColor = SKColor(red: 1, green: 0.8, blue: 0.2, alpha: 1)
            marker.isHidden = false
        case "active":
            marker.text = "?"
            marker.fontColor = SKColor(white: 0.85, alpha: 1)
            marker.isHidden = false
        default:
            marker.isHidden = true
        }
    }
}

// MARK: - Chest

final class ChestNode: SKSpriteNode {
    var chestId = ""
    var isOpen = false
    private var sparkle: SKSpriteNode?

    static func create(chestId: String, opened: Bool) -> ChestNode {
        let node = ChestNode(texture: TextureFactory.get(opened ? "chest_1" : "chest_0"))
        node.chestId = chestId
        node.isOpen = opened
        node.zPosition = 8
        if !opened {
            // Golden shimmer marks unopened chests.
            let glow = SKSpriteNode(texture: TextureFactory.get("glow"))
            glow.setScale(1.4)
            glow.alpha = 0.55
            glow.colorBlendFactor = 0.7
            glow.color = SKColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
            glow.zPosition = -1
            glow.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.6),
                SKAction.fadeAlpha(to: 0.7, duration: 0.6),
            ])))
            node.addChild(glow)
            node.sparkle = glow
        }
        return node
    }

    func open() {
        isOpen = true
        texture = TextureFactory.get("chest_1")
        sparkle?.removeFromParent()
        sparkle = nil
    }
}

// MARK: - Portal

final class PortalNode: SKSpriteNode {
    var locked = false
    private var glow: SKSpriteNode?

    static func create(locked: Bool) -> PortalNode {
        let node = PortalNode(texture: TextureFactory.get("portal_0"))
        node.locked = locked
        node.zPosition = 6
        node.run(SKAction.repeatForever(SKAction.animate(
            with: [TextureFactory.get("portal_0"), TextureFactory.get("portal_1"),
                   TextureFactory.get("portal_2"), TextureFactory.get("portal_3")],
            timePerFrame: 0.14)))
        let glow = SKSpriteNode(texture: TextureFactory.get("glow"))
        glow.setScale(2.4)
        glow.alpha = 0.5
        glow.zPosition = -1
        node.addChild(glow)
        node.glow = glow
        node.applyLock()
        return node
    }

    func setLocked(_ locked: Bool) {
        self.locked = locked
        applyLock()
    }

    private func applyLock() {
        if locked {
            colorBlendFactor = 0.75
            color = SKColor(white: 0.1, alpha: 1)
            glow?.alpha = 0.12
        } else {
            colorBlendFactor = 0
            glow?.alpha = 0.5
        }
    }
}

// MARK: - Checkpoint

final class CheckpointNode: SKSpriteNode {
    var checkpointId = ""
    var activated = false

    static func create(checkpointId: String, activated: Bool) -> CheckpointNode {
        let node = CheckpointNode(texture: TextureFactory.get(activated ? "flag_1" : "flag_0"))
        node.checkpointId = checkpointId
        node.activated = activated
        node.zPosition = 8
        return node
    }

    func activate() {
        activated = true
        texture = TextureFactory.get("flag_1")
    }
}

// MARK: - Sign

final class SignNode: SKSpriteNode {
    var text = ""
    var textRu: String?

    static func create(text: String, textRu: String?) -> SignNode {
        let node = SignNode(texture: TextureFactory.get("sign"))
        node.text = text
        node.textRu = textRu
        node.zPosition = 8
        return node
    }
}

// MARK: - Moving platform

final class MovingPlatformNode: SKSpriteNode {
    var home = CGPoint.zero
    var delta = CGVector.zero
    var period = 5.0
    var prevPos = CGPoint.zero

    static func create(w: CGFloat, h: CGFloat, dx: CGFloat, dy: CGFloat, period: Double, theme: String) -> MovingPlatformNode {
        let tileKey: String
        switch theme {
        case "caves": tileKey = "tile_stone"
        case "castle": tileKey = "tile_castle"
        case "sky": tileKey = "tile_cloud"
        default: tileKey = "tile_wood"
        }
        let node = MovingPlatformNode(texture: TextureFactory.get(tileKey), size: CGSize(width: w, height: h))
        node.centerRect = CGRect(x: 0.35, y: 0.35, width: 0.3, height: 0.3)
        node.delta = CGVector(dx: dx, dy: dy)
        node.period = period
        node.zPosition = 5
        let body = SKPhysicsBody(rectangleOf: CGSize(width: w, height: h))
        body.categoryBitMask = PhysicsCategory.moving
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.none
        body.isDynamic = false
        body.friction = 1.0
        node.physicsBody = body
        let move = SKAction.moveBy(x: dx, y: dy, duration: period / 2)
        move.timingMode = .easeInEaseOut
        let back = move.reversed()
        back.timingMode = .easeInEaseOut
        node.run(SKAction.repeatForever(SKAction.sequence([move, SKAction.wait(forDuration: 0.4), back, SKAction.wait(forDuration: 0.4)])))
        return node
    }
}

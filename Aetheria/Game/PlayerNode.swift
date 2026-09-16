import SpriteKit

protocol PlayerDelegate: AnyObject {
    func playerDidJump(doubleJump: Bool)
    func playerDidLand(fallSpeed: CGFloat)
    func playerDidDash(direction: CGFloat)
    func playerDidAttack(combo: Int)
    func playerDidCast()
}

/// The hero: platforming (coyote time, jump buffer, double jump, dash,
/// ladders), melee combos and spell hooks. Combat resolution lives in GameScene.
final class PlayerNode: SKSpriteNode {
    weak var delegate: PlayerDelegate?

    var facing: CGFloat = 1
    var groundedContacts = 0
    var grounded = false
    var onLadder = false
    var climbing = false
    var coyote = 0.0
    var jumpBuffer = 0.0
    var jumpsUsed = 0
    var attackCooldown = 0.0
    var comboWindow = 0.0
    var comboStep = 0
    var dashTime = 0.0
    var dashCooldown = 0.0
    var dashDir: CGFloat = 1
    var invulnerable = 0.0
    var hurtFlash = 0.0
    var classId = "knight"

    private var animTime = 0.0
    private var runDistance: CGFloat = 0
    private var textureKey = ""
    private var prevVy: CGFloat = 0

    static func create(classId: String) -> PlayerNode {
        let node = PlayerNode(texture: TextureFactory.get("player_\(classId)_idle_0"))
        node.classId = classId
        node.zPosition = 10
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 62), center: CGPoint(x: 0, y: -2))
        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform | PhysicsCategory.moving
        body.contactTestBitMask = PhysicsCategory.ground | PhysicsCategory.platform | PhysicsCategory.moving
        body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform | PhysicsCategory.moving
        body.allowsRotation = false
        body.friction = 0.1
        body.restitution = 0
        body.linearDamping = 0
        node.physicsBody = body
        return node
    }

    // MARK: - Per-frame update

    func update(dt: Double, input: InputState, derived: DerivedStats) {
        guard let body = physicsBody else { return }
        let d = dt
        prevVy = body.velocity.dy
        attackCooldown = max(0, attackCooldown - d)
        comboWindow = max(0, comboWindow - d)
        dashCooldown = max(0, dashCooldown - d)
        invulnerable = max(0, invulnerable - d)
        hurtFlash = max(0, hurtFlash - d)
        coyote = grounded ? 0.12 : max(0, coyote - d)
        if input.jumpQueued { jumpBuffer = 0.12 } else { jumpBuffer = max(0, jumpBuffer - d) }

        let ax = input.axisX
        if ax != 0 && dashTime <= 0 { facing = ax > 0 ? 1 : -1 }

        if climbing && (!onLadder || (grounded && input.axisY <= 0)) {
            climbing = false
            body.affectedByGravity = true
        }
        if onLadder && !grounded && input.axisY != 0 && dashTime <= 0 && !climbing {
            climbing = true
            body.affectedByGravity = false
            body.velocity = .zero
        }

        if climbing {
            body.velocity = CGVector(dx: ax * 140, dy: input.axisY * 230)
            if input.jumpQueued {
                climbing = false
                body.affectedByGravity = true
                body.velocity = CGVector(dx: ax * 220, dy: 620)
                jumpsUsed = 1
                grounded = false
                coyote = 0
                jumpBuffer = 0
                delegate?.playerDidJump(doubleJump: false)
            }
        } else if dashTime > 0 {
            dashTime -= d
            body.velocity = CGVector(dx: dashDir * 760, dy: 0)
            if dashTime <= 0 { body.velocity.dx = dashDir * 220 }
        } else {
            let target = ax * CGFloat(derived.moveSpeed)
            let accel: CGFloat = grounded ? 14 : 8
            body.velocity.dx += (target - body.velocity.dx) * min(1, CGFloat(d) * accel)
            if jumpBuffer > 0 {
                if grounded || coyote > 0 {
                    body.velocity.dy = 740
                    grounded = false
                    groundedContacts = 0
                    coyote = 0
                    jumpBuffer = 0
                    jumpsUsed = 1
                    delegate?.playerDidJump(doubleJump: false)
                } else if jumpsUsed < (derived.canDoubleJump ? 2 : 1) {
                    body.velocity.dy = 680
                    jumpsUsed += 1
                    jumpBuffer = 0
                    delegate?.playerDidJump(doubleJump: true)
                }
            }
            if !input.jumpHeld && body.velocity.dy > 300 {
                body.velocity.dy = 300
            }
            // One-way platforms: collide only when falling / standing.
            if body.velocity.dy > 60 {
                body.collisionBitMask = PhysicsCategory.ground
            } else {
                body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform | PhysicsCategory.moving
            }
        }

        if input.dashQueued && dashCooldown <= 0 && derived.canDash && !climbing {
            dashTime = 0.18
            dashCooldown = derived.dashCooldown
            dashDir = ax != 0 ? (ax > 0 ? 1 : -1) : facing
            facing = dashDir
            invulnerable = max(invulnerable, 0.3)
            delegate?.playerDidDash(direction: dashDir)
        }

        if input.attackQueued && attackCooldown <= 0 {
            let airborne = !grounded && !climbing
            if !airborne || derived.canAirAttack {
                comboStep = comboWindow > 0 ? min(comboStep + 1, 2) : 0
                comboWindow = 0.9
                attackCooldown = 0.36
                if grounded { body.velocity.dx *= 0.3 }
                delegate?.playerDidAttack(combo: comboStep)
            }
        }

        if input.spellQueued {
            delegate?.playerDidCast()
        }

        updateAnimation(dt: d)
    }

    // MARK: - Ground contact (called by the scene)

    func landed(contactY: CGFloat) {
        if position.y > contactY + 6 {
            let wasAirborne = !grounded
            groundedContacts += 1
            grounded = true
            if wasAirborne {
                jumpsUsed = 0
                delegate?.playerDidLand(fallSpeed: prevVy)
            }
        }
    }

    func leftGround() {
        groundedContacts = max(0, groundedContacts - 1)
        if groundedContacts == 0 { grounded = false }
    }

    // MARK: - Damage

    /// Returns true if the hit connected (false during i-frames / dash).
    @discardableResult
    func takeHit(knockback: CGFloat) -> Bool {
        if invulnerable > 0 || dashTime > 0 { return false }
        invulnerable = 0.9
        hurtFlash = 0.3
        physicsBody?.velocity.dx = knockback * 280
        if grounded { physicsBody?.velocity.dy = 280 }
        return true
    }

    // MARK: - Animation

    private func updateAnimation(dt: Double) {
        animTime += dt
        if let vx = physicsBody?.velocity.dx {
            runDistance += abs(vx) * CGFloat(dt)
        }
        var pose: String
        var frame = 0
        if dashTime > 0 {
            pose = "dash"
        } else if climbing {
            pose = "climb"
            frame = Int(animTime * 6) % 2
        } else if !grounded {
            pose = (physicsBody?.velocity.dy ?? 0) > 60 ? "jump" : "fall"
        } else if attackCooldown > 0.14 {
            pose = "attack"
            frame = comboStep
        } else if abs(physicsBody?.velocity.dx ?? 0) > 40 {
            pose = "run"
            frame = Int(runDistance / 34) % 4
        } else {
            pose = "idle"
            frame = Int(animTime * 2.5) % 2
        }
        let key = "player_\(classId)_\(pose)_\(frame)"
        if key != textureKey {
            textureKey = key
            texture = TextureFactory.get(key)
        }
        xScale = abs(xScale) * facing

        if hurtFlash > 0 {
            colorBlendFactor = 0.7
            color = .red
            alpha = 1
        } else if invulnerable > 0 && dashTime <= 0 {
            colorBlendFactor = 0
            alpha = 0.45 + 0.35 * sin(animTime * 30)
        } else {
            colorBlendFactor = 0
            alpha = 1
        }
    }
}

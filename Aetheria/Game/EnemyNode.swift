import SpriteKit

protocol EnemyDelegate: AnyObject {
    func enemyShoot(from: CGPoint, velocity: CGVector, damage: Double, kind: String)
    func enemyDealTouchDamage(_ enemy: EnemyNode, amount: Double)
    func enemyAoE(at point: CGPoint, radius: CGFloat, damage: Double)
    func enemyTelegraphCircle(at point: CGPoint, radius: CGFloat, duration: Double)
    func enemyTelegraphRect(_ rect: CGRect, duration: Double)
    func enemySummon(type: String, at point: CGPoint)
    func enemyPuff(at point: CGPoint, big: Bool)
    func enemyDied(_ enemy: EnemyNode)
}

enum EnemyState {
    case patrol, chase, windup, attack, recover, hurt, dead
}

private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    hypot(a.x - b.x, a.y - b.y)
}

/// All regular enemies share one FSM; behavior is driven by EnemyDefinition.
class EnemyNode: SKSpriteNode {
    weak var delegate: EnemyDelegate?

    var def: EnemyDefinition!
    var maxHp: Double = 10
    var hp: Double = 10
    var damageMul: Double = 1
    var state: EnemyState = .patrol
    var stateTime = 0.0
    var attackCd = 1.0
    var touchCd = 0.0
    var specialCd = 0.0
    var facing: CGFloat = 1
    var anchor = CGPoint.zero
    var patrolDir: CGFloat = 1
    var active = false
    var isBoss = false
    var touchMultiplier = 1.0
    var elite = false
    var speedMul: CGFloat = 1

    private var animTime = 0.0
    private var flash = 0.0
    private var hopCd = 0.0
    private var sineT = Double.random(in: 0...10)
    private var hpBg: SKSpriteNode?
    private var hpFg: SKSpriteNode?

    var isDead: Bool { state == .dead }
    var damage: Double { def.damage * damageMul }
    var aggroRadius: CGFloat { 430 }
    var leashRadius: CGFloat { 750 }
    var touchRadius: CGFloat { max(size.width, size.height) * 0.42 + 26 }

    static func create(def: EnemyDefinition) -> EnemyNode {
        let node = EnemyNode(texture: TextureFactory.get("enemy_\(def.id)_0"))
        node.def = def
        node.maxHp = def.hp
        node.hp = def.hp
        node.anchor = .zero
        node.zPosition = 9
        let s = CGFloat(def.scale)
        node.setScale(s)
        if !def.flying && def.behavior != "ghost" {
            let body = SKPhysicsBody(rectangleOf: CGSize(width: node.size.width * 0.6, height: node.size.height * 0.85))
            body.categoryBitMask = PhysicsCategory.enemy
            body.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.platform | PhysicsCategory.moving
            body.contactTestBitMask = PhysicsCategory.none
            body.allowsRotation = false
            body.friction = 1.0
            body.linearDamping = 0.5
            node.physicsBody = body
        }
        return node
    }

    // MARK: - Update

    func update(dt: Double, playerPos: CGPoint) {
        if isDead { return }
        animTime += dt
        attackCd = max(0, attackCd - dt)
        touchCd = max(0, touchCd - dt)
        specialCd = max(0, specialCd - dt)
        flash = max(0, flash - dt)
        stateTime += dt

        let d = dist(position, playerPos)
        if !active {
            if d < 1050 { active = true } else { return }
        }

        if d > 1600 {
            // Far away: freeze to save CPU.
            physicsBody?.velocity = .zero
            return
        }

        if state != .hurt {
            facing = playerPos.x >= position.x ? 1 : -1
        }

        // Touch damage.
        if d < touchRadius && touchCd <= 0 && state != .dead {
            touchCd = 1.0
            delegate?.enemyDealTouchDamage(self, amount: damage * touchMultiplier)
        }

        switch def.behavior {
        case "hopper": updateHopper(dt: dt, playerPos: playerPos, d: d)
        case "flyer", "ghost": updateFlyer(dt: dt, playerPos: playerPos, d: d)
        case "shooter": updateShooter(dt: dt, playerPos: playerPos, d: d)
        case "charger": updateCharger(dt: dt, playerPos: playerPos, d: d)
        case "mage": updateMage(dt: dt, playerPos: playerPos, d: d)
        default: updateHopper(dt: dt, playerPos: playerPos, d: d)
        }

        xScale = abs(xScale) * facing
        // HP bar is a child: counter-flip so it never mirrors when facing left.
        hpBg?.xScale = facing
        if flash > 0 {
            colorBlendFactor = 0.8
            color = .white
        } else if elite {
            colorBlendFactor = 0.35
            color = SKColor(red: 1, green: 0.8, blue: 0.3, alpha: 1)
        } else {
            colorBlendFactor = 0
            color = .white
        }
    }

    /// Promotes this enemy to an elite: tougher, golden, worth more.
    func makeElite() {
        guard !elite, !isBoss else { return }
        elite = true
        maxHp *= 1.6
        hp = maxHp
        damageMul *= 1.25
        setScale(xScale * 1.12)
    }

    // MARK: - Behaviors

    private func groundSpeed() -> CGFloat { CGFloat(def.speed) * speedMul }

    private func updateHopper(dt: Double, playerPos: CGPoint, d: CGFloat) {
        guard state != .hurt else { return }
        hopCd -= dt
        let vy = physicsBody?.velocity.dy ?? 0
        let grounded = abs(vy) < 60
        setFrame(grounded ? 0 : 1)
        if grounded { physicsBody?.velocity.dx *= 0.8 }
        if hopCd <= 0 && grounded {
            var dir: CGFloat
            if d < aggroRadius {
                dir = playerPos.x >= position.x ? 1 : -1
                state = .chase
            } else {
                state = .patrol
                if abs(position.x - anchor.x) > 220 { patrolDir = position.x > anchor.x ? -1 : 1 }
                else if Double.random(in: 0...1) < 0.25 { patrolDir *= -1 }
                dir = patrolDir
            }
            physicsBody?.velocity = CGVector(dx: dir * groundSpeed() * 2.1, dy: 360)
            hopCd = 0.7 + Double.random(in: 0...0.5)
        }
    }

    private func updateFlyer(dt: Double, playerPos: CGPoint, d: CGFloat) {
        sineT += dt * 3
        guard state != .hurt else { return }
        setFrame(Int(animTime * 6) % 2)
        var target: CGPoint
        if d < aggroRadius {
            state = .chase
            target = playerPos
        } else {
            state = .patrol
            target = CGPoint(x: anchor.x + sin(sineT * 0.4) * 120, y: anchor.y + sin(sineT * 0.7) * 40)
        }
        let dx = target.x - position.x, dy = target.y - position.y
        let len = max(1, hypot(dx, dy))
        let sp = groundSpeed() * (state == .chase ? 1.15 : 0.5)
        position.x += dx / len * sp * CGFloat(dt) + cos(sineT) * 24 * CGFloat(dt)
        position.y += dy / len * sp * CGFloat(dt) * 0.8 + sin(sineT * 1.3) * 20 * CGFloat(dt)
        // Ghosts spit projectiles.
        if def.behavior == "ghost" && d < CGFloat(def.attackRange) && attackCd <= 0 {
            attackCd = def.attackCooldown
            setFrame(1)
            let v = CGVector(dx: dx / len * CGFloat(def.projectileSpeed), dy: dy / len * CGFloat(def.projectileSpeed))
            delegate?.enemyShoot(from: position, velocity: v, damage: damage, kind: "slimeball")
        }
    }

    private func updateShooter(dt: Double, playerPos: CGPoint, d: CGFloat) {
        let range = CGFloat(def.attackRange)
        switch state {
        case .hurt: return
        case .windup:
            setFrame(2)
            physicsBody?.velocity.dx = 0
            if stateTime > 0.35 {
                state = .recover
                stateTime = 0
                let dx = playerPos.x - position.x, dy = (playerPos.y - 10) - position.y
                let len = max(1, hypot(dx, dy))
                let sp = CGFloat(def.projectileSpeed)
                delegate?.enemyShoot(from: position, velocity: CGVector(dx: dx / len * sp, dy: dy / len * sp), damage: damage, kind: "arrow_red")
            }
        case .recover:
            setFrame(0)
            if stateTime > 0.4 { state = .chase; stateTime = 0 }
        default:
            setFrame(Int(animTime * 5) % 2)
            if d > range {
                state = .chase
                physicsBody?.velocity.dx = facing * groundSpeed()
            } else if d < range * 0.45 {
                physicsBody?.velocity.dx = -facing * groundSpeed() * 0.8
            } else {
                physicsBody?.velocity.dx *= 0.85
                if attackCd <= 0 {
                    attackCd = def.attackCooldown
                    state = .windup
                    stateTime = 0
                }
            }
        }
    }

    private func updateCharger(dt: Double, playerPos: CGPoint, d: CGFloat) {
        _ = playerPos
        switch state {
        case .hurt: return
        case .windup:
            setFrame(0)
            physicsBody?.velocity.dx = 0
            // Shake telegraph.
            position.x += CGFloat.random(in: -2...2)
            if stateTime > 0.45 {
                state = .attack
                stateTime = 0
                touchMultiplier = 1.5
                delegate?.enemyPuff(at: position, big: false)
            }
        case .attack:
            setFrame(2)
            physicsBody?.velocity.dx = facing * groundSpeed() * 3.4
            touchCd = min(touchCd, 0.15)
            if stateTime > 0.5 {
                state = .recover
                stateTime = 0
                touchMultiplier = 1.0
            }
        case .recover:
            setFrame(0)
            physicsBody?.velocity.dx *= 0.85
            if stateTime > 0.6 { state = .chase; stateTime = 0 }
        default:
            setFrame(Int(animTime * 5) % 2)
            if d < aggroRadius * 1.3 {
                state = .chase
                physicsBody?.velocity.dx = facing * groundSpeed()
                if d < 280 && attackCd <= 0 {
                    attackCd = 3.0
                    state = .windup
                    stateTime = 0
                }
            } else {
                state = .patrol
                if abs(position.x - anchor.x) > 200 { patrolDir = position.x > anchor.x ? -1 : 1 }
                physicsBody?.velocity.dx = patrolDir * groundSpeed() * 0.5
            }
        }
    }

    private func updateMage(dt: Double, playerPos: CGPoint, d: CGFloat) {
        let range = CGFloat(def.attackRange)
        switch state {
        case .hurt: return
        case .windup:
            setFrame(2)
            physicsBody?.velocity.dx = 0
            if stateTime > 0.5 {
                state = .recover
                stateTime = 0
                // 3-fireball spread.
                let base = atan2(playerPos.y - position.y, playerPos.x - position.x)
                for off in [-0.22, 0.0, 0.22] {
                    let a = base + off
                    let sp = CGFloat(def.projectileSpeed)
                    delegate?.enemyShoot(from: position, velocity: CGVector(dx: cos(a) * sp, dy: sin(a) * sp), damage: damage, kind: "fireball")
                }
            }
        case .recover:
            setFrame(0)
            if stateTime > 0.5 { state = .chase; stateTime = 0 }
        default:
            setFrame(Int(animTime * 3) % 2)
            if d < 220 {
                if specialCd <= 0 {
                    specialCd = 4.0
                    teleportAway(from: playerPos)
                } else {
                    physicsBody?.velocity.dx = -facing * groundSpeed()
                }
            } else if d < range {
                physicsBody?.velocity.dx *= 0.85
                if attackCd <= 0 {
                    attackCd = def.attackCooldown
                    state = .windup
                    stateTime = 0
                }
            } else {
                physicsBody?.velocity.dx = facing * groundSpeed() * 0.7
            }
        }
    }

    private func teleportAway(from playerPos: CGPoint) {
        delegate?.enemyPuff(at: position, big: true)
        let dir: CGFloat = position.x >= playerPos.x ? 1 : -1
        var nx = position.x + dir * 320
        nx = min(max(nx, anchor.x - leashRadius), anchor.x + leashRadius)
        let move = SKAction.moveTo(x: nx, duration: 0.05)
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.22), move,
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                guard let self else { return }
                self.delegate?.enemyPuff(at: self.position, big: true)
            },
            SKAction.fadeIn(withDuration: 0.22),
        ]))
    }

    // MARK: - Damage

    func setFrame(_ f: Int) {
        texture = TextureFactory.get("enemy_\(def.id)_\(min(f, 2))")
    }

    /// Applies damage; returns true if this killed the enemy.
    @discardableResult
    func takeDamage(_ amount: Double, crit: Bool, fromDir: CGFloat) -> Bool {
        if isDead { return true }
        _ = crit
        hp -= amount
        flash = 0.12
        active = true
        showHpBar()
        if hp <= 0 {
            die()
            return true
        }
        if state != .attack {
            state = .hurt
            stateTime = 0
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.22),
                SKAction.run { [weak self] in
                    guard let self, self.state == .hurt else { return }
                    self.state = .chase
                },
            ]))
        }
        if let body = physicsBody {
            body.velocity.dx = fromDir * 220
        } else {
            position.x += fromDir * 10
        }
        return false
    }

    func die() {
        state = .dead
        physicsBody = nil
        delegate?.enemyDied(self)
    }

    private func showHpBar() {
        if hpBg == nil {
            let w: CGFloat = 46
            let bg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.6), size: CGSize(width: w, height: 6))
            bg.position = CGPoint(x: 0, y: size.height / 2 + 10)
            bg.zPosition = 5
            let fg = SKSpriteNode(color: SKColor(red: 0.3, green: 0.9, blue: 0.35, alpha: 1), size: CGSize(width: w - 2, height: 4))
            fg.anchorPoint = CGPoint(x: 0, y: 0.5)
            fg.position = CGPoint(x: -(w - 2) / 2, y: 0)
            bg.addChild(fg)
            addChild(bg)
            hpBg = bg
            hpFg = fg
        }
        hpBg?.isHidden = false
        let k = CGFloat(max(0, hp / maxHp))
        hpFg?.xScale = max(0.001, k)
        hpFg?.color = k > 0.5 ? SKColor(red: 0.3, green: 0.9, blue: 0.35, alpha: 1)
            : (k > 0.25 ? SKColor(red: 1, green: 0.8, blue: 0.2, alpha: 1) : SKColor(red: 1, green: 0.3, blue: 0.3, alpha: 1))
    }
}

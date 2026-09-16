import SpriteKit

/// Bosses: multi-phase pattern schedulers with telegraphed attacks.
final class BossNode: EnemyNode {
    var shortId = "golem"
    var phase = 1
    var patternT = 2.0
    var patternIndex = 0
    var patternStep = 0
    var summoned66 = false
    var summoned33 = false
    var baseY: CGFloat = 0
    var diveTarget = CGPoint.zero
    private var bossTime = 0.0

    static func createBoss(def: EnemyDefinition) -> BossNode {
        let node = BossNode(texture: TextureFactory.get("boss_\(def.id.replacingOccurrences(of: "boss_", with: ""))_0"))
        node.def = def
        node.maxHp = def.hp
        node.hp = def.hp
        node.isBoss = true
        node.shortId = def.id.replacingOccurrences(of: "boss_", with: "")
        node.zPosition = 9
        node.setScale(CGFloat(def.scale))
        if !def.flying {
            let body = SKPhysicsBody(rectangleOf: CGSize(width: node.size.width * 0.55, height: node.size.height * 0.9))
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

    override func update(dt: Double, playerPos: CGPoint) {
        if isDead { return }
        let d = hypot(position.x - playerPos.x, position.y - playerPos.y)
        if !active {
            if d < 900 {
                active = true
                baseY = position.y
            } else { return }
        }
        animTime()
        bossTime += dt
        attackCd = max(0, attackCd - dt)
        touchCd = max(0, touchCd - dt)
        facing = playerPos.x >= position.x ? 1 : -1
        if d < touchRadius && touchCd <= 0 {
            touchCd = 1.0
            delegate?.enemyDealTouchDamage(self, damage * touchMultiplier)
        }

        // Phase transitions.
        let frac = hp / maxHp
        let newPhase = def.phases >= 3 ? (frac < 0.33 ? 3 : (frac < 0.66 ? 2 : 1)) : (frac < 0.55 ? 2 : 1)
        if newPhase != phase {
            phase = newPhase
            patternT = 0.5
            delegate?.enemyPuff(at: position, big: true)
        }

        switch shortId {
        case "golem": updateGolem(dt: dt, playerPos: playerPos, d: d)
        case "knight": updateKnight(dt: dt, playerPos: playerPos, d: d)
        case "dragon": updateDragon(dt: dt, playerPos: playerPos, d: d)
        default: break
        }
        xScale = abs(xScale) * facing
    }

    private func animTime() {
        // Reuse parent flash decay via a no-op damage-free path.
    }

    // MARK: - Golem

    private func updateGolem(dt: Double, playerPos: CGPoint, d: CGFloat) {
        // Lumbers toward the player.
        physicsBody?.velocity.dx = facing * CGFloat(def.speed) * (phase >= 2 ? 1.3 : 1.0)
        if Int(bossTime * 4) % 2 == 0 { texture = TextureFactory.get("boss_golem_0") } else { texture = TextureFactory.get("boss_golem_1") }
        patternT -= dt
        if patternT > 0 { return }
        if d > 700 && patternIndex != 1 {
            patternIndex = 1 // throw rocks at range
        }
        switch patternIndex % (phase >= 2 ? 3 : 2) {
        case 0: // Slam: telegraphed AoE around self.
            state = .windup
            texture = TextureFactory.get("boss_golem_2")
            delegate?.enemyTelegraphCircle(at: position, radius: 210, duration: 0.8)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.8),
                SKAction.run { [weak self] in
                    guard let self, !self.isDead else { return }
                    self.delegate?.enemyAoE(at: self.position, radius: 210, damage: self.damage * 1.2)
                    self.delegate?.enemyPuff(at: self.position, big: true)
                    if self.phase >= 2 {
                        for i in 0..<5 {
                            let a = Double(i) * .pi * 2 / 5
                            self.delegate?.enemyShoot(from: self.position, velocity: CGVector(dx: cos(a) * 380, dy: abs(sin(a)) * 420 + 150), damage: self.damage * 0.7, kind: "rock")
                        }
                    }
                    self.state = .chase
                },
            ]))
            patternT = phase >= 2 ? 2.6 : 3.4
        default: // Rock throw.
            state = .windup
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    guard let self, !self.isDead else { return }
                    let dx = playerPos.x - self.position.x
                    let n = self.phase >= 2 ? 3 : 1
                    for i in 0..<n {
                        let spread = CGFloat(i - n / 2) * 90
                        self.delegate?.enemyShoot(from: self.position, velocity: CGVector(dx: dx * 1.4 + spread, dy: 520), damage: self.damage * 0.8, kind: "rock")
                    }
                    self.state = .chase
                },
            ]))
            patternT = 2.8
        }
        patternIndex += 1
    }

    // MARK: - Knight

    private func updateKnight(dt: Double, playerPos: CGPoint, d: CGFloat) {
        _ = d
        // Phase summons.
        let frac = hp / maxHp
        if frac < 0.66 && !summoned66 {
            summoned66 = true
            delegate?.enemySummon(type: "skeleton", at: position + CGPoint(x: -140, y: 60))
            delegate?.enemySummon(type: "skeleton", at: position + CGPoint(x: 140, y: 60))
        }
        if frac < 0.33 && !summoned33 {
            summoned33 = true
            delegate?.enemySummon(type: "orc", at: position + CGPoint(x: -160, y: 60))
            delegate?.enemySummon(type: "skeleton", at: position + CGPoint(x: 160, y: 60))
        }
        texture = TextureFactory.get("boss_knight_\(Int(bossTime * 5) % 2)")
        patternT -= dt
        if patternT > 0 {
            if state != .attack { physicsBody?.velocity.dx = facing * CGFloat(def.speed) * 0.6 }
            return
        }
        switch patternIndex % (phase >= 2 ? 3 : 2) {
        case 0, 1: // Dash slash through the player.
            state = .windup
            let dashX = playerPos.x
            let rect = CGRect(x: min(position.x, dashX) - 60, y: position.y - 80, width: abs(dashX - position.x) + 120, height: 160)
            delegate?.enemyTelegraphRect(rect, duration: 0.55)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.55),
                SKAction.run { [weak self] in
                    guard let self, !self.isDead else { return }
                    self.state = .attack
                    self.touchMultiplier = 1.4
                    self.touchCd = 0
                    self.texture = TextureFactory.get("boss_knight_2")
                    let dir: CGFloat = dashX >= self.position.x ? 1 : -1
                    self.physicsBody?.velocity = CGVector(dx: dir * 900, dy: 0)
                },
                SKAction.wait(forDuration: 0.45),
                SKAction.run { [weak self] in
                    self?.state = .chase
                    self?.touchMultiplier = 1.0
                },
            ]))
            patternT = phase >= 3 ? 1.8 : 2.4
        default: // Sword waves.
            state = .windup
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                SKAction.run { [weak self] in
                    guard let self, !self.isDead else { return }
                    let n = self.phase >= 3 ? 5 : 3
                    for i in 0..<n {
                        let spread = CGFloat(i - n / 2) * 130
                        self.delegate?.enemyShoot(from: self.position, velocity: CGVector(dx: self.facing * 520, dy: spread), damage: self.damage * 0.75, kind: "wave")
                    }
                    self.texture = TextureFactory.get("boss_knight_2")
                    self.state = .chase
                },
            ]))
            patternT = 2.2
        }
        patternIndex += 1
    }

    // MARK: - Dragon

    private func updateDragon(dt: Double, playerPos: CGPoint, d: CGFloat) {
        _ = d
        let frac = hp / maxHp
        if frac < 0.5 && !summoned66 {
            summoned66 = true
            delegate?.enemySummon(type: "bat", at: position + CGPoint(x: -120, y: 0))
            delegate?.enemySummon(type: "bat", at: position + CGPoint(x: 120, y: 0))
        }
        texture = TextureFactory.get("boss_dragon_\(Int(bossTime * 4) % 2)")
        // Hover.
        if state != .attack {
            let targetX = playerPos.x + sin(bossTime * 0.9) * 160
            let targetY = baseY + sin(bossTime * 1.7) * 50
            position.x += (targetX - position.x) * min(1, dt * 1.6)
            position.y += (targetY - position.y) * min(1, dt * 1.6)
        }
        patternT -= dt
        if patternT > 0 { return }
        switch patternIndex % 3 {
        case 0: // Fire breath: spread of fireballs downward.
            state = .windup
            texture = TextureFactory.get("boss_dragon_2")
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.6),
                SKAction.run { [weak self] in
                    guard let self, !self.isDead else { return }
                    let n = self.phase >= 2 ? 7 : 5
                    for i in 0..<n {
                        let t = Double(i) / Double(max(1, n - 1)) - 0.5
                        self.delegate?.enemyShoot(from: self.position, velocity: CGVector(dx: t * 640, dy: -460), damage: self.damage * 0.7, kind: "fireball")
                    }
                    self.state = .chase
                },
            ]))
            patternT = 2.6
        case 1: // Dive: telegraphed swoop to the player's ground.
            state = .windup
            diveTarget = CGPoint(x: playerPos.x, y: playerPos.y)
            delegate?.enemyTelegraphCircle(at: diveTarget, radius: 170, duration: 0.75)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.75),
                SKAction.run { [weak self] in
                    guard let self else { return }
                    self.state = .attack
                    self.touchMultiplier = 1.5
                    self.touchCd = 0
                },
                SKAction.move(to: diveTarget, duration: 0.4),
                SKAction.run { [weak self] in
                    guard let self, !self.isDead else { return }
                    self.delegate?.enemyAoE(at: self.position, radius: 170, damage: self.damage * 1.2)
                    self.delegate?.enemyPuff(at: self.position, big: true)
                },
                SKAction.moveTo(y: baseY, duration: 0.7),
                SKAction.run { [weak self] in
                    self?.state = .chase
                    self?.touchMultiplier = 1.0
                },
            ]))
            patternT = 3.2
        default: // Radial burst (phase 2+) or aimed volley.
            state = .windup
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    guard let self, !self.isDead else { return }
                    if self.phase >= 2 {
                        for i in 0..<10 {
                            let a = Double(i) * .pi * 2 / 10
                            self.delegate?.enemyShoot(from: self.position, velocity: CGVector(dx: cos(a) * 420, dy: sin(a) * 420), damage: self.damage * 0.6, kind: "fireball")
                        }
                    } else {
                        for i in 0..<3 {
                            let dx = playerPos.x - self.position.x, dy = playerPos.y - self.position.y
                            let len = max(1, hypot(dx, dy))
                            let sp: CGFloat = 460
                            self.delegate?.enemyShoot(from: self.position, velocity: CGVector(dx: dx / len * sp + CGFloat(i - 1) * 90, dy: dy / len * sp), damage: self.damage * 0.7, kind: "fireball")
                        }
                    }
                    self.state = .chase
                },
            ]))
            patternT = 2.4
        }
        patternIndex += 1
    }

    // Bosses don't get knocked back and show no small HP bar (scene draws the boss bar).
    override func takeDamage(_ amount: Double, crit: Bool, fromDir: CGFloat) -> Bool {
        if isDead { return true }
        _ = crit
        _ = fromDir
        hp -= amount
        active = true
        if hp <= 0 {
            die()
            return true
        }
        return false
    }

    override func setFrame(_ f: Int) {
        texture = TextureFactory.get("boss_\(shortId)_\(min(f, 2))")
    }
}

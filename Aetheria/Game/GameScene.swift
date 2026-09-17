import SpriteKit

extension GameScene {
    func spawnDustBurst(at pos: CGPoint, color: SKColor = .white, count: Int = 8, radius: CGFloat = 45, upward: CGFloat = 16) {
        world.addBurst(at: pos, count: count, color: color, radius: radius, duration: 0.6, upward: upward)
    }

    func spawnDashTrail(at pos: CGPoint, color: SKColor) {
        let glow = SKSpriteNode(texture: VisualFX.glowTexture(color: UIColor(color), size: 26))
        glow.position = pos
        glow.alpha = 0.65
        glow.zPosition = 9
        glow.setScale(0.5)
        world.addChild(glow)
        glow.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.8, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    func spawnImpactRing(at pos: CGPoint, color: SKColor, radius: CGFloat = 42) {
        let ring = SKSpriteNode(texture: VisualFX.glowTexture(color: UIColor(color), size: radius * 2))
        ring.position = pos
        ring.alpha = 0.75
        ring.zPosition = 11
        ring.setScale(0.25)
        world.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.35, duration: 0.18),
                SKAction.fadeOut(withDuration: 0.18)
            ]),
            SKAction.removeFromParent()
        ]))
    }
}

extension GameScene {
    func applyImprovedCombatVFX() {
        // Hooked by gameplay callbacks below; kept as a shared extension for future polish.
    }
}

// MARK: - Gameplay callbacks for better visual feedback

extension GameScene {
    func playerDidJump(doubleJump: Bool) {
        guard let vm = viewModel else { return }
        vm.session.stats.jumps += 1
        SoundManager.shared.play(doubleJump ? "doubleJump" : "jump")
        spawnDustBurst(at: player.position + CGPoint(x: 0, y: -30), color: doubleJump ? .cyan : .white, count: doubleJump ? 11 : 8, radius: 32)
        if doubleJump {
            puff(at: player.position + CGPoint(x: 0, y: -30), big: false, color: .white)
            spawnImpactRing(at: player.position + CGPoint(x: 0, y: -22), color: .cyan, radius: 24)
        }
    }

    func playerDidLand(fallSpeed: CGFloat) {
        if fallSpeed < -900 {
            SoundManager.shared.play("land")
            puff(at: player.position + CGPoint(x: 0, y: -30), big: false, color: SKColor(white: 1, alpha: 0.7))
            spawnDustBurst(at: player.position + CGPoint(x: 0, y: -22), color: .gray, count: 10, radius: 36, upward: 8)
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
        spawnDashTrail(at: player.position + CGPoint(x: player.facing * -12, y: 0), color: .cyan)
        spawnDustBurst(at: player.position + CGPoint(x: player.facing * -18, y: -18), color: .cyan, count: 6, radius: 28, upward: 8)
    }

    func playerDidAttack(combo: Int) {
        SoundManager.shared.play("swing")
        let slash = SKSpriteNode(texture: VisualFX.slashTexture(color: SKColor(red: 1, green: 0.85, blue: 0.35, alpha: 1), width: 128, height: 64))
        slash.position = player.position + CGPoint(x: player.facing * 55, y: 5)
        slash.xScale = player.facing
        slash.zPosition = 11
        world.addChild(slash)
        slash.run(SKAction.sequence([
            SKAction.group([SKAction.fadeOut(withDuration: 0.18), SKAction.scale(to: 1.3, duration: 0.18)]),
            SKAction.removeFromParent(),
        ]))
        performMeleeHit(combo: combo)
        spawnImpactRing(at: player.position + CGPoint(x: player.facing * 42, y: 5), color: .yellow, radius: 20)
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
        spawnImpactRing(at: bolt.position, color: .cyan, radius: 22)
        spawnDustBurst(at: bolt.position, color: .cyan, count: 7, radius: 28, upward: 12)
    }

    func enemyHitVFX(at pos: CGPoint, crit: Bool) {
        let color: SKColor = crit ? .yellow : .white
        spawnImpactRing(at: pos, color: color, radius: crit ? 28 : 18)
        spawnDustBurst(at: pos, color: color, count: crit ? 12 : 8, radius: crit ? 44 : 32, upward: 12)
    }
}

// MARK: - Hook the new visual effects into existing game callbacks

extension GameScene {
    override func hitEnemy(_ enemy: EnemyNode, damage: Double, crit: Bool, fromX: CGFloat) {
        guard let vm = viewModel else { return }
        let dir: CGFloat = enemy.position.x >= fromX ? 1 : -1
        let killed = enemy.takeDamage(damage, crit: crit, fromDir: dir)
        vm.session.stats.damageDealt += damage
        damageLayer.spawn(text: "\(Int(damage))", at: enemy.position + CGPoint(x: 0, y: enemy.size.height / 2),
                          color: crit ? SKColor(red: 1, green: 0.75, blue: 0.2, alpha: 1) : .white, big: crit)
        enemyHitVFX(at: enemy.position + CGPoint(x: 0, y: 10), crit: crit)
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
}

extension PlayerNode {
    func applyMotionStyle(dt: Double) {
        let runBoost = abs(physicsBody?.velocity.dx ?? 0) > 40 ? 1.0 + 0.05 * sin(animTime * 12) : 1.0
        let matchScale = grounded ? runBoost : 1.0 + 0.03 * sin(animTime * 8)
        setScale(CGFloat(matchScale))
        yScale = grounded ? 1.0 : 1.0 + 0.04 * sin(animTime * 9)
    }
}

extension PlayerNode {
    override func updateAnimation(dt: Double) {
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
        let motionBoost = abs(physicsBody?.velocity.dx ?? 0) > 40 ? 1.0 + 0.06 * sin(animTime * 12) : 1.0
        setScale(CGFloat(motionBoost))
        yScale = !grounded ? 1.0 + 0.08 * sin(animTime * 14) : 1.0

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

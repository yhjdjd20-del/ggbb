import SpriteKit

// MARK: - Combat VFX helpers (dust bursts, dash trails, impact rings)
//
// Small spawn helpers that layer VisualFX primitives into gameplay
// callbacks (jump, dash, hits). SKColor is a UIColor typealias on iOS,
// so colors pass straight through without conversion.

extension GameScene {
    func spawnDustBurst(at pos: CGPoint, color: SKColor = .white, count: Int = 8, radius: CGFloat = 45, upward: CGFloat = 16) {
        world.addBurst(at: pos, count: count, color: color, radius: radius, duration: 0.6, upward: upward)
    }

    func spawnDashTrail(at pos: CGPoint, color: SKColor) {
        // Cached 64px "glow" tinted (no per-spawn texture render).
        let glow = SKSpriteNode(texture: TextureFactory.get("glow"))
        glow.position = pos
        glow.alpha = 0.65
        glow.zPosition = 9
        glow.colorBlendFactor = 1.0
        glow.color = color
        glow.setScale(0.2)
        world.addChild(glow)
        glow.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.75, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2),
            ]),
            SKAction.removeFromParent(),
        ]))
    }

    func spawnImpactRing(at pos: CGPoint, color: SKColor, radius: CGFloat = 42) {
        // Cached 64px "glow" tinted (no per-spawn texture render).
        let ring = SKSpriteNode(texture: TextureFactory.get("glow"))
        ring.position = pos
        ring.alpha = 0.75
        ring.zPosition = 11
        ring.colorBlendFactor = 1.0
        ring.color = color
        let base = radius * 2 / 64
        ring.setScale(base * 0.25)
        world.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: base * 1.35, duration: 0.18),
                SKAction.fadeOut(withDuration: 0.18),
            ]),
            SKAction.removeFromParent(),
        ]))
    }

    func enemyHitVFX(at pos: CGPoint, crit: Bool) {
        let color: SKColor = crit ? .yellow : .white
        spawnImpactRing(at: pos, color: color, radius: crit ? 28 : 18)
        spawnDustBurst(at: pos, color: color, count: crit ? 12 : 8, radius: crit ? 44 : 32, upward: 12)
    }
}

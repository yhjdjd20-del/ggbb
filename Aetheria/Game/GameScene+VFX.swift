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
        let glow = SKSpriteNode(texture: VisualFX.glowTexture(color: color, size: 26))
        glow.position = pos
        glow.alpha = 0.65
        glow.zPosition = 9
        glow.setScale(0.5)
        world.addChild(glow)
        glow.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.8, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2),
            ]),
            SKAction.removeFromParent(),
        ]))
    }

    func spawnImpactRing(at pos: CGPoint, color: SKColor, radius: CGFloat = 42) {
        let ring = SKSpriteNode(texture: VisualFX.glowTexture(color: color, size: radius * 2))
        ring.position = pos
        ring.alpha = 0.75
        ring.zPosition = 11
        ring.setScale(0.25)
        world.addChild(ring)
        ring.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.35, duration: 0.18),
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

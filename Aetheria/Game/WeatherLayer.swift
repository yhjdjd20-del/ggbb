import SpriteKit

/// Full-screen weather particles + day/night tint (child of the camera).
final class WeatherLayer: SKNode {
    private var emitter: SKEmitterNode?
    private var tint: SKSpriteNode!
    private var current = "none"

    func setup() {
        zPosition = 40
        tint = SKSpriteNode(color: SKColor(white: 0, alpha: 0), size: CGSize(width: 2000, height: 2000))
        tint.zPosition = 2
        addChild(tint)
    }

    func layout(size: CGSize) {
        tint.size = CGSize(width: size.width + 200, height: size.height + 200)
        emitter?.position = CGPoint(x: 0, y: size.height / 2)
        emitter?.particlePositionRange = CGVector(dx: size.width + 100, dy: 60)
    }

    func configure(weather: String, timeOfDay: Double, size: CGSize) {
        current = weather
        emitter?.removeFromParent()
        emitter = nil
        if weather != "none" {
            let node = SKEmitterNode()
            node.zPosition = 1
            node.targetNode = self
            switch weather {
            case "rain":
                node.particleTexture = TextureFactory.get("rain")
                node.particleBirthRate = 160
                node.particleLifetime = 1.1
                node.particleSpeed = 1400
                node.particleSpeedRange = 150
                node.emissionAngle = -CGFloat.pi / 2 + 0.18
                node.particleAlpha = 0.7
                node.particleScale = 1.0
            case "snow":
                node.particleTexture = TextureFactory.get("snow")
                node.particleBirthRate = 55
                node.particleLifetime = 9.0
                node.particleSpeed = 90
                node.particleSpeedRange = 40
                node.emissionAngle = -CGFloat.pi / 2
                node.particleAlpha = 0.9
                node.particleScale = 1.0
                node.particleScaleRange = 0.8
                node.xAcceleration = 30
            case "ash":
                node.particleTexture = TextureFactory.get("ash")
                node.particleBirthRate = 30
                node.particleLifetime = 6.0
                node.particleSpeed = 45
                node.particleSpeedRange = 30
                node.emissionAngle = CGFloat.pi / 2
                node.particleAlpha = 0.6
                node.particleScaleRange = 1.0
                node.xAcceleration = -14
            default: // leaves
                node.particleTexture = TextureFactory.get("leaf")
                node.particleBirthRate = 18
                node.particleLifetime = 12.0
                node.particleSpeed = 70
                node.particleSpeedRange = 40
                node.emissionAngle = -CGFloat.pi / 2 + 0.4
                node.particleAlpha = 0.9
                node.particleRotationRange = 6.28
                node.particleRotationSpeed = 2.0
            }
            node.particleBirthRate *= AppSettings.shared.particleScale
            addChild(node)
            emitter = node
            node.advanceSimulationTime(3)
        }
        // Day/night tint.
        let bucket = TextureFactory.skyBucket(for: timeOfDay)
        switch bucket {
        case 0: tint.color = SKColor(red: 0.02, green: 0.03, blue: 0.12, alpha: 0.42)
        case 1: tint.color = SKColor(red: 0.25, green: 0.12, blue: 0.2, alpha: 0.18)
        case 3: tint.color = SKColor(red: 0.3, green: 0.1, blue: 0.15, alpha: 0.22)
        default: tint.color = SKColor(white: 0, alpha: 0)
        }
        layout(size: size)
    }
}

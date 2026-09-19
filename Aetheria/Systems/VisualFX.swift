import SpriteKit
import UIKit

/// Procedural VFX helpers used to add richer combat polish without external art assets.
enum VisualFX {
    static func glowTexture(color: UIColor, size: CGFloat = 64) -> SKTexture {
        let image = UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { ctx in
            let c = ctx.cgContext
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            c.clear(rect)
            c.setShadow(offset: .zero, blur: 18, color: color.withAlphaComponent(0.9).cgColor)
            c.setFillColor(color.withAlphaComponent(0.7).cgColor)
            c.fillEllipse(in: CGRect(x: size * 0.18, y: size * 0.18, width: size * 0.64, height: size * 0.64))
            c.setFillColor(color.withAlphaComponent(0.35).cgColor)
            c.fillEllipse(in: CGRect(x: size * 0.28, y: size * 0.28, width: size * 0.44, height: size * 0.44))
        }
        return SKTexture(image: image)
    }

    static func sparkTexture(color: UIColor, size: CGFloat = 12) -> SKTexture {
        let image = UIGraphicsImageRenderer(size: CGSize(width: size, height: size)).image { ctx in
            let c = ctx.cgContext
            c.setFillColor(color.cgColor)
            let r = CGRect(x: size * 0.42, y: 0, width: size * 0.16, height: size)
            c.fill(r)
            let rr = CGRect(x: 0, y: size * 0.42, width: size, height: size * 0.16)
            c.fill(rr)
            c.rotate(by: .pi / 4)
            c.fill(r)
            c.fill(rr)
        }
        return SKTexture(image: image)
    }

    static func slashTexture(color: UIColor, width: CGFloat = 140, height: CGFloat = 64) -> SKTexture {
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { ctx in
            let c = ctx.cgContext
            c.setFillColor(color.withAlphaComponent(0.9).cgColor)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: height * 0.5))
            path.addQuadCurve(to: CGPoint(x: width * 0.75, y: height * 0.5), control: CGPoint(x: width * 0.4, y: height * 0.12))
            path.addQuadCurve(to: CGPoint(x: width, y: height * 0.5), control: CGPoint(x: width * 0.9, y: height * 0.5))
            path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.75))
            path.addQuadCurve(to: CGPoint(x: 0, y: height * 0.5), control: CGPoint(x: width * 0.55, y: height * 0.9))
            path.closeSubpath()
            c.addPath(path)
            c.fillPath()
        }
        return SKTexture(image: image)
    }
}

extension SKNode {
    func addBurst(at position: CGPoint,
                  count: Int = 8,
                  color: SKColor,
                  radius: CGFloat = 50,
                  duration: TimeInterval = 0.55,
                  upward: CGFloat = 10) {
        // NOTE: uses the cached white "spark" texture (tinted) instead of
        // rendering a new texture per particle (was a CPU spike on every burst).
        let tex = TextureFactory.get("spark")
        for _ in 0..<count {
            let s = SKSpriteNode(texture: tex)
            s.position = position
            s.zPosition = zPosition + 1
            s.setScale(CGFloat.random(in: 0.5...1.2))
            s.alpha = 0.9
            s.colorBlendFactor = 1.0
            s.color = color
            addChild(s)
            let dx = CGFloat.random(in: -radius...radius)
            let dy = CGFloat.random(in: -radius * 0.4...radius * 0.8 + upward)
            let action = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: duration),
                    SKAction.fadeOut(withDuration: duration),
                    SKAction.scale(to: 0.15, duration: duration)
                ]),
                SKAction.removeFromParent()
            ])
            s.run(action)
        }
    }
}

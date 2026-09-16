import UIKit
import SpriteKit

// MARK: - World, items, effects, backgrounds
extension TextureFactory {
    enum TileStyle { case grass, speckle, brick, crack, plank }

    static func drawTile(base: String, top: String?, style: TileStyle) -> SKTexture {
        render(64, 64) { ctx, r in
            fill(ctx, rect: r, color: UIColor(hex: base))
            let dark = UIColor(hex: base).darkened(0.75)
            let light = UIColor(hex: base).lightened(0.2)
            switch style {
            case .grass:
                if let top {
                    fill(ctx, rect: CGRect(x: 0, y: 0, width: 64, height: 16), color: UIColor(hex: top))
                    fill(ctx, rect: CGRect(x: 0, y: 14, width: 64, height: 4), color: UIColor(hex: top).darkened(0.8))
                    for x in stride(from: 2, to: 64, by: 9) {
                        poly(ctx, points: [CGPoint(x: x, y: 2), CGPoint(x: x + 4, y: 2), CGPoint(x: x + 2, y: -4)], color: UIColor(hex: top))
                    }
                }
                for i in 0..<8 {
                    let x = CGFloat((i * 37) % 56), y = CGFloat(20 + (i * 23) % 40)
                    circle(ctx, center: CGPoint(x: x, y: y), radius: 2, color: dark)
                }
            case .speckle:
                for i in 0..<12 {
                    let x = CGFloat((i * 37) % 58), y = CGFloat((i * 29) % 58)
                    circle(ctx, center: CGPoint(x: x, y: y), radius: 2.5, color: i % 2 == 0 ? dark : light)
                }
            case .brick:
                fill(ctx, rect: CGRect(x: 0, y: 30, width: 64, height: 3), color: dark)
                fill(ctx, rect: CGRect(x: 30, y: 0, width: 3, height: 30), color: dark)
                fill(ctx, rect: CGRect(x: 14, y: 33, width: 3, height: 31), color: dark)
                fill(ctx, rect: CGRect(x: 46, y: 33, width: 3, height: 31), color: dark)
                if let top {
                    fill(ctx, rect: CGRect(x: 0, y: 0, width: 64, height: 8), color: UIColor(hex: top))
                }
            case .crack:
                line(ctx, from: CGPoint(x: 8, y: 6), to: CGPoint(x: 26, y: 30), width: 3, color: dark)
                line(ctx, from: CGPoint(x: 26, y: 30), to: CGPoint(x: 20, y: 52), width: 3, color: dark)
                line(ctx, from: CGPoint(x: 44, y: 12), to: CGPoint(x: 52, y: 40), width: 2, color: dark)
                circle(ctx, center: CGPoint(x: 46, y: 50), radius: 3, color: light)
                circle(ctx, center: CGPoint(x: 12, y: 44), radius: 2, color: light)
            case .plank:
                for y in [0, 21, 42] {
                    fill(ctx, rect: CGRect(x: 0, y: CGFloat(y), width: 64, height: 3), color: dark)
                    for x in [12, 40] {
                        circle(ctx, center: CGPoint(x: CGFloat(x), y: CGFloat(y) + 12), radius: 2, color: dark)
                    }
                }
                if let top {
                    fill(ctx, rect: CGRect(x: 0, y: 0, width: 64, height: 4), color: UIColor(hex: top))
                }
            }
        }
    }

    static func drawCloudTile() -> SKTexture {
        render(64, 64) { ctx, _ in
            ellipse(ctx, rect: CGRect(x: 2, y: 18, width: 60, height: 40), color: UIColor(hex: "#EAF4FF"))
            ellipse(ctx, rect: CGRect(x: 8, y: 8, width: 48, height: 30), color: .white)
            ellipse(ctx, rect: CGRect(x: 14, y: 40, width: 36, height: 14), color: UIColor(hex: "#C9DCF2"))
        }
    }

    static func drawSpikes() -> SKTexture {
        render(64, 32) { ctx, _ in
            fill(ctx, rect: CGRect(x: 0, y: 26, width: 64, height: 6), color: UIColor(hex: "#3A3A44"))
            for i in 0..<4 {
                let x = CGFloat(i * 16)
                poly(ctx, points: [CGPoint(x: x, y: 28), CGPoint(x: x + 16, y: 28), CGPoint(x: x + 8, y: 2)],
                     color: UIColor(hex: "#B9C2D0"))
                poly(ctx, points: [CGPoint(x: x + 8, y: 28), CGPoint(x: x + 16, y: 28), CGPoint(x: x + 8, y: 2)],
                     color: UIColor(hex: "#7E8898"))
            }
        }
    }

    static func drawLava(frame: Int) -> SKTexture {
        render(64, 32) { ctx, _ in
            fill(ctx, rect: CGRect(x: 0, y: 0, width: 64, height: 32), color: UIColor(hex: "#E2481F"))
            fill(ctx, rect: CGRect(x: 0, y: 0, width: 64, height: 8), color: UIColor(hex: "#FFC46B"))
            let off: CGFloat = frame == 0 ? 0 : 10
            for i in 0..<4 {
                let x = CGFloat((i * 19 + Int(off)) % 58)
                circle(ctx, center: CGPoint(x: x, y: 18 + CGFloat((i * 13) % 10)), radius: 3.5, color: UIColor(hex: "#FFE66D"))
            }
        }
    }

    static func drawCoin() -> SKTexture {
        render(28, 28) { ctx, _ in
            circle(ctx, center: CGPoint(x: 14, y: 14), radius: 12, color: UIColor(hex: "#C9A227"))
            circle(ctx, center: CGPoint(x: 14, y: 14), radius: 9, color: UIColor(hex: "#FFD95E"))
            circle(ctx, center: CGPoint(x: 11, y: 11), radius: 3, color: UIColor(hex: "#FFF3C4"))
        }
    }

    static func drawHeart() -> SKTexture {
        render(30, 28) { ctx, _ in
            circle(ctx, center: CGPoint(x: 10, y: 12), radius: 8, color: UIColor(hex: "#FF4D6D"))
            circle(ctx, center: CGPoint(x: 20, y: 12), radius: 8, color: UIColor(hex: "#FF4D6D"))
            poly(ctx, points: [CGPoint(x: 3, y: 14), CGPoint(x: 27, y: 14), CGPoint(x: 15, y: 27)], color: UIColor(hex: "#FF4D6D"))
            circle(ctx, center: CGPoint(x: 8, y: 9), radius: 2.5, color: UIColor(hex: "#FFB3C1"))
        }
    }

    static func drawMana() -> SKTexture {
        render(28, 28) { ctx, _ in
            circle(ctx, center: CGPoint(x: 14, y: 14), radius: 11, color: UIColor(hex: "#3FA7F5", alpha: 0.4))
            circle(ctx, center: CGPoint(x: 14, y: 14), radius: 8, color: UIColor(hex: "#3FA7F5"))
            circle(ctx, center: CGPoint(x: 11, y: 11), radius: 3, color: UIColor(hex: "#C4E8FF"))
        }
    }

    static func drawItemGlow() -> SKTexture {
        render(44, 44) { ctx, _ in
            poly(ctx, points: [CGPoint(x: 22, y: 2), CGPoint(x: 30, y: 22), CGPoint(x: 22, y: 42), CGPoint(x: 14, y: 22)],
                 color: UIColor(hex: "#FFE66D"))
            poly(ctx, points: [CGPoint(x: 22, y: 10), CGPoint(x: 26, y: 22), CGPoint(x: 22, y: 34), CGPoint(x: 18, y: 22)],
                 color: .white)
        }
    }

    static func drawKey() -> SKTexture {
        render(32, 24) { ctx, _ in
            circle(ctx, center: CGPoint(x: 8, y: 12), radius: 7, color: UIColor(hex: "#FFD95E"))
            circle(ctx, center: CGPoint(x: 8, y: 12), radius: 3.5, color: UIColor(hex: "#1A1A22", alpha: 0))
            fill(ctx, rect: CGRect(x: 13, y: 10, width: 17, height: 4), color: UIColor(hex: "#FFD95E"))
            fill(ctx, rect: CGRect(x: 24, y: 10, width: 3, height: 9), color: UIColor(hex: "#FFD95E"))
            fill(ctx, rect: CGRect(x: 28, y: 10, width: 3, height: 6), color: UIColor(hex: "#FFD95E"))
        }
    }

    static func drawChest(open: Bool) -> SKTexture {
        render(76, 60) { ctx, _ in
            let wood = UIColor(hex: "#7A5230")
            if open {
                poly(ctx, points: [CGPoint(x: 8, y: 34), CGPoint(x: 68, y: 34), CGPoint(x: 60, y: 6), CGPoint(x: 14, y: 6)], color: wood.darkened(0.8))
                ellipse(ctx, rect: CGRect(x: 16, y: 14, width: 44, height: 26), color: UIColor(hex: "#FFE66D", alpha: 0.75))
                round(ctx, rect: CGRect(x: 8, y: 30, width: 60, height: 26), radius: 6, color: wood)
            } else {
                round(ctx, rect: CGRect(x: 8, y: 18, width: 60, height: 38), radius: 6, color: wood)
                round(ctx, rect: CGRect(x: 8, y: 8, width: 60, height: 18), radius: 8, color: wood.lightened(0.15))
                fill(ctx, rect: CGRect(x: 34, y: 8, width: 8, height: 48), color: UIColor(hex: "#C9A227"))
                round(ctx, rect: CGRect(x: 31, y: 26, width: 14, height: 14), radius: 4, color: UIColor(hex: "#3A2A1A"))
            }
            fill(ctx, rect: CGRect(x: 8, y: 30, width: 6, height: 26), color: wood.darkened(0.75))
            fill(ctx, rect: CGRect(x: 62, y: 30, width: 6, height: 26), color: wood.darkened(0.75))
        }
    }

    static func drawFlag(active: Bool) -> SKTexture {
        render(52, 100) { ctx, _ in
            round(ctx, rect: CGRect(x: 20, y: 88, width: 16, height: 10), radius: 3, color: UIColor(hex: "#4A4A55"))
            fill(ctx, rect: CGRect(x: 25, y: 8, width: 6, height: 82), color: UIColor(hex: "#6B4A2B"))
            let color = active ? UIColor(hex: "#3FD97C") : UIColor(hex: "#7E8898")
            poly(ctx, points: [CGPoint(x: 31, y: 10), CGPoint(x: 31, y: 36), CGPoint(x: 50, y: 23)], color: color)
            if active {
                circle(ctx, center: CGPoint(x: 28, y: 6), radius: 5, color: UIColor(hex: "#BFFFC9", alpha: 0.8))
            }
        }
    }

    static func drawSign() -> SKTexture {
        render(52, 68) { ctx, _ in
            fill(ctx, rect: CGRect(x: 23, y: 30, width: 6, height: 38), color: UIColor(hex: "#5A3A22"))
            round(ctx, rect: CGRect(x: 4, y: 4, width: 44, height: 30), radius: 6, color: UIColor(hex: "#8A6238"))
            round(ctx, rect: CGRect(x: 4, y: 4, width: 44, height: 30), radius: 6, color: UIColor(hex: "#000000", alpha: 0))
            fill(ctx, rect: CGRect(x: 10, y: 12, width: 32, height: 3), color: UIColor(hex: "#4E3420"))
            fill(ctx, rect: CGRect(x: 10, y: 19, width: 24, height: 3), color: UIColor(hex: "#4E3420"))
            fill(ctx, rect: CGRect(x: 10, y: 26, width: 28, height: 3), color: UIColor(hex: "#4E3420"))
        }
    }

    static func drawLadder() -> SKTexture {
        render(48, 64) { ctx, _ in
            fill(ctx, rect: CGRect(x: 6, y: 0, width: 6, height: 64), color: UIColor(hex: "#6B4A2B"))
            fill(ctx, rect: CGRect(x: 36, y: 0, width: 6, height: 64), color: UIColor(hex: "#6B4A2B"))
            for y in stride(from: 4, to: 64, by: 14) {
                fill(ctx, rect: CGRect(x: 6, y: CGFloat(y), width: 36, height: 5), color: UIColor(hex: "#8A6238"))
            }
        }
    }

    static func drawPortal(frame: Int) -> SKTexture {
        render(100, 144) { ctx, _ in
            let cols = ["#B45CFF", "#7DF9FF", "#B45CFF", "#FF7BFF"]
            let main = UIColor(hex: cols[frame % 4])
            ellipse(ctx, rect: CGRect(x: 18, y: 6, width: 64, height: 132), color: main.darkened(0.5))
            ellipse(ctx, rect: CGRect(x: 26, y: 16, width: 48, height: 112), color: main)
            let innerH = 96 - frame * 4
            ellipse(ctx, rect: CGRect(x: 34, y: 72 - innerH / 2, width: 32, height: innerH), color: UIColor(hex: "#0A0A18"))
            for i in 0..<6 {
                let a = Double(frame) * 0.5 + Double(i) * 1.05
                let px = 50 + cos(a) * 30, py = 72 + sin(a) * 58
                circle(ctx, center: CGPoint(x: px, y: py), radius: 4, color: .white)
            }
            ellipse(ctx, rect: CGRect(x: 12, y: 126, width: 76, height: 12), color: UIColor(hex: "#2A2A3E"))
        }
    }

    // MARK: - Projectiles & effects

    static func drawArrow(color: String) -> SKTexture {
        render(36, 14) { ctx, _ in
            fill(ctx, rect: CGRect(x: 4, y: 6, width: 26, height: 3), color: UIColor(hex: "#8A6D3B"))
            poly(ctx, points: [CGPoint(x: 28, y: 2), CGPoint(x: 28, y: 12), CGPoint(x: 36, y: 7)], color: UIColor(hex: color))
            poly(ctx, points: [CGPoint(x: 0, y: 6), CGPoint(x: 7, y: 2), CGPoint(x: 7, y: 11)], color: UIColor(hex: "#DDDDDD"))
        }
    }

    static func drawFireball(frame: Int) -> SKTexture {
        render(32, 32) { ctx, _ in
            circle(ctx, center: CGPoint(x: 16, y: 16), radius: 13, color: UIColor(hex: "#FF7B2E", alpha: 0.5))
            circle(ctx, center: CGPoint(x: 16, y: 16), radius: 9, color: UIColor(hex: "#FF7B2E"))
            circle(ctx, center: CGPoint(x: 16, y: 16), radius: frame == 0 ? 5 : 6, color: UIColor(hex: "#FFE66D"))
        }
    }

    static func drawBolt() -> SKTexture {
        render(32, 32) { ctx, _ in
            circle(ctx, center: CGPoint(x: 16, y: 16), radius: 13, color: UIColor(hex: "#7DF9FF", alpha: 0.45))
            circle(ctx, center: CGPoint(x: 16, y: 16), radius: 8, color: UIColor(hex: "#7DF9FF"))
            circle(ctx, center: CGPoint(x: 16, y: 16), radius: 4, color: .white)
        }
    }

    static func drawBone() -> SKTexture {
        render(32, 16) { ctx, _ in
            fill(ctx, rect: CGRect(x: 6, y: 6, width: 20, height: 4), color: UIColor(hex: "#E8E4D8"))
            circle(ctx, center: CGPoint(x: 5, y: 8), radius: 4, color: UIColor(hex: "#E8E4D8"))
            circle(ctx, center: CGPoint(x: 27, y: 8), radius: 4, color: UIColor(hex: "#E8E4D8"))
        }
    }

    static func drawSlimeball() -> SKTexture {
        render(26, 26) { ctx, _ in
            circle(ctx, center: CGPoint(x: 13, y: 13), radius: 11, color: UIColor(hex: "#58D68D", alpha: 0.5))
            circle(ctx, center: CGPoint(x: 13, y: 13), radius: 7, color: UIColor(hex: "#58D68D"))
        }
    }

    static func drawRock() -> SKTexture {
        render(30, 30) { ctx, _ in
            poly(ctx, points: [CGPoint(x: 4, y: 22), CGPoint(x: 10, y: 6), CGPoint(x: 24, y: 8), CGPoint(x: 27, y: 22), CGPoint(x: 14, y: 28)],
                 color: UIColor(hex: "#6E6A85"))
            circle(ctx, center: CGPoint(x: 14, y: 15), radius: 3, color: UIColor(hex: "#8E8AA5"))
        }
    }

    static func drawSlash(frame: Int) -> SKTexture {
        render(72, 72) { ctx, _ in
            ctx.setStrokeColor(UIColor(hex: "#FFFFFF", alpha: 0.9).cgColor)
            ctx.setLineWidth(CGFloat(10 - frame * 2))
            ctx.setLineCap(.round)
            ctx.beginPath()
            let cx: CGFloat = 36, cy: CGFloat = 36, rad: CGFloat = 26 - CGFloat(frame) * 3
            ctx.addArc(center: CGPoint(x: cx, y: cy), radius: rad,
                       startAngle: CGFloat(frame) * 0.5 - 0.6, endAngle: CGFloat(frame) * 0.5 + 1.4, clockwise: false)
            ctx.strokePath()
        }
    }

    static func drawBoom(frame: Int) -> SKTexture {
        render(104, 104) { ctx, _ in
            let r = CGFloat(14 + frame * 11)
            let cols = ["#FFF3C4", "#FFC46B", "#FF7B2E", "#B9B3A8"]
            circle(ctx, center: CGPoint(x: 52, y: 52), radius: r + 8, color: UIColor(hex: cols[frame], alpha: 0.4))
            circle(ctx, center: CGPoint(x: 52, y: 52), radius: r, color: UIColor(hex: cols[frame]))
        }
    }

    static func drawSpark() -> SKTexture {
        render(20, 20) { ctx, _ in
            poly(ctx, points: [CGPoint(x: 10, y: 0), CGPoint(x: 13, y: 10), CGPoint(x: 10, y: 20), CGPoint(x: 7, y: 10)], color: .white)
            poly(ctx, points: [CGPoint(x: 0, y: 10), CGPoint(x: 10, y: 7), CGPoint(x: 20, y: 10), CGPoint(x: 10, y: 13)], color: .white)
        }
    }

    static func drawGlow() -> SKTexture {
        render(64, 64) { ctx, _ in
            for i in stride(from: 30, through: 6, by: -6) {
                circle(ctx, center: CGPoint(x: 32, y: 32), radius: CGFloat(i),
                       color: UIColor(hex: "#FFFFFF", alpha: 0.08 + CGFloat(30 - i) * 0.008))
            }
        }
    }

    static func drawShadow() -> SKTexture {
        render(56, 18) { ctx, _ in
            ellipse(ctx, rect: CGRect(x: 2, y: 2, width: 52, height: 14), color: UIColor(hex: "#000000", alpha: 0.35))
        }
    }

    static func drawPuff(frame: Int) -> SKTexture {
        render(40, 40) { ctx, _ in
            let r: CGFloat = frame == 0 ? 10 : 15
            circle(ctx, center: CGPoint(x: 20, y: 20), radius: r, color: UIColor(hex: "#D8D4CC", alpha: frame == 0 ? 0.8 : 0.5))
            circle(ctx, center: CGPoint(x: 14, y: 16), radius: r * 0.5, color: UIColor(hex: "#FFFFFF", alpha: 0.6))
        }
    }

    static func drawStreak(color: String) -> SKTexture {
        render(8, 26) { ctx, _ in
            line(ctx, from: CGPoint(x: 5, y: 1), to: CGPoint(x: 3, y: 25), width: 2.5, color: UIColor(hex: color, alpha: 0.7))
        }
    }

    static func drawDot(color: String, r: CGFloat) -> SKTexture {
        render(r * 2 + 4, r * 2 + 4) { ctx, _ in
            circle(ctx, center: CGPoint(x: r + 2, y: r + 2), radius: r, color: UIColor(hex: color, alpha: 0.85))
        }
    }

    static func drawLeaf() -> SKTexture {
        render(16, 16) { ctx, _ in
            ellipse(ctx, rect: CGRect(x: 2, y: 4, width: 12, height: 8), color: UIColor(hex: "#3FD97C"))
            line(ctx, from: CGPoint(x: 2, y: 8), to: CGPoint(x: 14, y: 8), width: 1.5, color: UIColor(hex: "#2C7A43"))
        }
    }

    static func drawTelegraph() -> SKTexture {
        render(64, 64) { ctx, r in
            fill(ctx, rect: r, color: UIColor(hex: "#FF3B3B", alpha: 0.35))
            fill(ctx, rect: CGRect(x: 0, y: 0, width: 64, height: 4), color: UIColor(hex: "#FF3B3B", alpha: 0.8))
            fill(ctx, rect: CGRect(x: 0, y: 60, width: 64, height: 4), color: UIColor(hex: "#FF3B3B", alpha: 0.8))
        }
    }

    // MARK: - Decorations

    static func drawTorch(frame: Int) -> SKTexture {
        render(32, 72) { ctx, _ in
            fill(ctx, rect: CGRect(x: 13, y: 30, width: 6, height: 42), color: UIColor(hex: "#5A3A22"))
            round(ctx, rect: CGRect(x: 10, y: 24, width: 12, height: 10), radius: 3, color: UIColor(hex: "#3A2A1A"))
            let h: CGFloat = frame == 0 ? 22 : 26
            poly(ctx, points: [CGPoint(x: 8, y: 26), CGPoint(x: 24, y: 26), CGPoint(x: 16, y: 26 - h)], color: UIColor(hex: "#FF7B2E"))
            poly(ctx, points: [CGPoint(x: 12, y: 26), CGPoint(x: 20, y: 26), CGPoint(x: 16, y: 26 - h * 0.55)], color: UIColor(hex: "#FFE66D"))
        }
    }

    static func drawCrystal() -> SKTexture {
        render(56, 72) { ctx, _ in
            let c = UIColor(hex: "#7DF9FF")
            poly(ctx, points: [CGPoint(x: 28, y: 2), CGPoint(x: 42, y: 34), CGPoint(x: 34, y: 68), CGPoint(x: 22, y: 68), CGPoint(x: 14, y: 34)], color: c)
            poly(ctx, points: [CGPoint(x: 28, y: 2), CGPoint(x: 34, y: 34), CGPoint(x: 30, y: 68), CGPoint(x: 24, y: 68), CGPoint(x: 22, y: 34)],
                 color: UIColor(hex: "#D8FBFF"))
            circle(ctx, center: CGPoint(x: 28, y: 60), radius: 14, color: UIColor(hex: "#7DF9FF", alpha: 0.25))
        }
    }

    static func drawTree() -> SKTexture {
        render(128, 170) { ctx, _ in
            fill(ctx, rect: CGRect(x: 56, y: 100, width: 16, height: 70), color: UIColor(hex: "#5A3A22"))
            fill(ctx, rect: CGRect(x: 60, y: 100, width: 5, height: 70), color: UIColor(hex: "#3E2818"))
            let leaf = UIColor(hex: "#2C7A43")
            circle(ctx, center: CGPoint(x: 64, y: 60), radius: 52, color: leaf)
            circle(ctx, center: CGPoint(x: 34, y: 85), radius: 30, color: leaf.darkened(0.85))
            circle(ctx, center: CGPoint(x: 94, y: 85), radius: 30, color: leaf.darkened(0.85))
            circle(ctx, center: CGPoint(x: 48, y: 45), radius: 18, color: leaf.lightened(0.2))
        }
    }

    static func drawBush() -> SKTexture {
        render(84, 52) { ctx, _ in
            let leaf = UIColor(hex: "#35945A")
            circle(ctx, center: CGPoint(x: 24, y: 30), radius: 20, color: leaf)
            circle(ctx, center: CGPoint(x: 46, y: 24), radius: 22, color: leaf.lightened(0.1))
            circle(ctx, center: CGPoint(x: 64, y: 32), radius: 16, color: leaf.darkened(0.9))
        }
    }

    static func drawRockDeco() -> SKTexture {
        render(68, 44) { ctx, _ in
            let rock = UIColor(hex: "#7E8898")
            poly(ctx, points: [CGPoint(x: 4, y: 42), CGPoint(x: 20, y: 8), CGPoint(x: 48, y: 10), CGPoint(x: 64, y: 42)], color: rock)
            poly(ctx, points: [CGPoint(x: 20, y: 8), CGPoint(x: 48, y: 10), CGPoint(x: 40, y: 30), CGPoint(x: 24, y: 28)], color: rock.lightened(0.2))
        }
    }

    static func drawTuft() -> SKTexture {
        render(52, 26) { ctx, _ in
            let g = UIColor(hex: "#3FD97C")
            for i in 0..<7 {
                let x = CGFloat(4 + i * 7)
                let h = CGFloat(12 + (i * 11) % 12)
                poly(ctx, points: [CGPoint(x: x, y: 26), CGPoint(x: x + 5, y: 26), CGPoint(x: x + 2 + CGFloat(i % 3 - 1) * 2, y: 26 - h)], color: i % 2 == 0 ? g : g.darkened(0.85))
            }
        }
    }

    static func drawMushroom() -> SKTexture {
        render(44, 52) { ctx, _ in
            round(ctx, rect: CGRect(x: 17, y: 22, width: 10, height: 30), radius: 4, color: UIColor(hex: "#D8D4CC"))
            ellipse(ctx, rect: CGRect(x: 4, y: 4, width: 36, height: 26), color: UIColor(hex: "#7DF9FF", alpha: 0.9))
            circle(ctx, center: CGPoint(x: 16, y: 16), radius: 3, color: .white)
            circle(ctx, center: CGPoint(x: 28, y: 14), radius: 2.5, color: .white)
            circle(ctx, center: CGPoint(x: 22, y: 40), radius: 14, color: UIColor(hex: "#7DF9FF", alpha: 0.2))
        }
    }

    static func drawBanner() -> SKTexture {
        render(52, 100) { ctx, _ in
            fill(ctx, rect: CGRect(x: 4, y: 4, width: 44, height: 6), color: UIColor(hex: "#5A3A22"))
            poly(ctx, points: [CGPoint(x: 8, y: 10), CGPoint(x: 44, y: 10), CGPoint(x: 44, y: 84), CGPoint(x: 26, y: 96), CGPoint(x: 8, y: 84)],
                 color: UIColor(hex: "#8F1D2E"))
            circle(ctx, center: CGPoint(x: 26, y: 40), radius: 9, color: UIColor(hex: "#C9A227"))
            circle(ctx, center: CGPoint(x: 26, y: 40), radius: 5, color: UIColor(hex: "#8F1D2E"))
        }
    }

    static func drawCloudDeco() -> SKTexture {
        render(170, 84) { ctx, _ in
            let c = UIColor(hex: "#FFFFFF", alpha: 0.85)
            ellipse(ctx, rect: CGRect(x: 10, y: 30, width: 60, height: 40), color: c)
            ellipse(ctx, rect: CGRect(x: 50, y: 14, width: 70, height: 52), color: c)
            ellipse(ctx, rect: CGRect(x: 100, y: 32, width: 60, height: 38), color: c)
        }
    }

    static func drawStalactite() -> SKTexture {
        render(68, 100) { ctx, _ in
            let rock = UIColor(hex: "#4A4468")
            poly(ctx, points: [CGPoint(x: 4, y: 0), CGPoint(x: 64, y: 0), CGPoint(x: 40, y: 100)], color: rock)
            poly(ctx, points: [CGPoint(x: 24, y: 0), CGPoint(x: 44, y: 0), CGPoint(x: 36, y: 70)], color: rock.lightened(0.15))
        }
    }

    static func drawPillar() -> SKTexture {
        render(84, 210) { ctx, _ in
            let stone = UIColor(hex: "#5B6685")
            fill(ctx, rect: CGRect(x: 22, y: 20, width: 40, height: 170), color: stone)
            fill(ctx, rect: CGRect(x: 28, y: 20, width: 8, height: 170), color: stone.darkened(0.85))
            fill(ctx, rect: CGRect(x: 48, y: 20, width: 8, height: 170), color: stone.darkened(0.85))
            round(ctx, rect: CGRect(x: 12, y: 4, width: 60, height: 20), radius: 4, color: stone.lightened(0.2))
            round(ctx, rect: CGRect(x: 12, y: 186, width: 60, height: 20), radius: 4, color: stone.lightened(0.2))
        }
    }

    // MARK: - Skies & parallax

    static func skyBucket(for timeOfDay: Double) -> Int {
        if timeOfDay < 0.15 || timeOfDay > 0.9 { return 0 } // night
        if timeOfDay < 0.3 { return 1 } // dawn
        if timeOfDay < 0.7 { return 2 } // day
        return 3 // dusk
    }

    static func drawSky(theme: String, bucket: Int) -> SKTexture {
        render(16, 256) { ctx, r in
            let palettes: [String: [[String]]] = [
                "forest": [["#060818", "#141B3D"], ["#2A3A5E", "#C9714A"], ["#3E7CC4", "#BFE3FF"], ["#3A2A5E", "#E2703A"]],
                "caves": [["#050309", "#120E1E"], ["#0E0A18", "#241A3E"], ["#120E24", "#3B2F5E"], ["#0A0714", "#2A1A3E"]],
                "castle": [["#080A18", "#1A2340"], ["#2E3A5E", "#B96A4A"], ["#4A6EA9", "#C9DCF2"], ["#2E2A5E", "#C25A3A"]],
                "sky": [["#060818", "#1A2A5E"], ["#5E7EC9", "#FFC4A3"], ["#4DA3FF", "#D8F4FF"], ["#5E3A8F", "#FF9A5E"]],
            ]
            let pal = palettes[theme] ?? palettes["forest"]!
            let cols = pal[bucket % pal.count]
            let top = UIColor(hex: cols[0]), bottom = UIColor(hex: cols[1])
            for y in 0..<256 {
                let k = CGFloat(y) / 255.0
                var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, a: CGFloat = 0
                top.getRed(&tr, green: &tg, blue: &tb, alpha: &a)
                bottom.getRed(&br, green: &bg, blue: &bb, alpha: &a)
                fill(ctx, rect: CGRect(x: 0, y: y, width: 16, height: 1),
                     color: UIColor(red: tr + (br - tr) * k, green: tg + (bg - tg) * k, blue: tb + (bb - tb) * k, alpha: 1))
            }
            if bucket == 0 {
                // Stars
                for i in 0..<24 {
                    let x = CGFloat((i * 53) % 14) + 1, y = CGFloat((i * 97) % 200)
                    circle(ctx, center: CGPoint(x: x, y: y), radius: 1, color: .white)
                }
            }
            _ = r
        }
    }

    static func drawParallax(theme: String, layer: Int) -> SKTexture {
        render(512, 256) { ctx, _ in
            let alpha: CGFloat = [0.5, 0.7, 0.9][min(layer, 2)]
            switch theme {
            case "caves":
                let c = UIColor(hex: "#241F3D", alpha: alpha)
                for i in 0..<6 {
                    let x = CGFloat(i * 90 + layer * 30)
                    let h = CGFloat(120 + ((i * 67 + layer * 40) % 90))
                    poly(ctx, points: [CGPoint(x: x, y: 256), CGPoint(x: x + 45, y: 256 - h), CGPoint(x: x + 90, y: 256)], color: c)
                }
            case "castle":
                let c = UIColor(hex: "#232A44", alpha: alpha)
                for i in 0..<5 {
                    let x = CGFloat(i * 110 + layer * 25)
                    let h = CGFloat(130 + ((i * 53 + layer * 30) % 70))
                    fill(ctx, rect: CGRect(x: x, y: 256 - h, width: 56, height: h), color: c)
                    poly(ctx, points: [CGPoint(x: x - 6, y: 256 - h), CGPoint(x: x + 62, y: 256 - h), CGPoint(x: x + 28, y: 256 - h - 40)], color: c)
                }
            case "sky":
                let c = UIColor(hex: "#FFFFFF", alpha: 0.35 + CGFloat(layer) * 0.15)
                for i in 0..<5 {
                    let x = CGFloat((i * 130 + layer * 60) % 480)
                    let y = CGFloat(60 + (i * 47 + layer * 50) % 150)
                    ellipse(ctx, rect: CGRect(x: x, y: y, width: 90, height: 34), color: c)
                }
            default: // forest
                let cols = ["#1E3A2E", "#26493A", "#2F5A48"]
                let c = UIColor(hex: cols[min(layer, 2)], alpha: alpha)
                for i in 0..<8 {
                    let x = CGFloat(i * 70 + layer * 35)
                    let h = CGFloat(110 + ((i * 71 + layer * 45) % 80))
                    fill(ctx, rect: CGRect(x: x + 20, y: 256 - h * 0.4, width: 12, height: h * 0.4), color: c)
                    poly(ctx, points: [CGPoint(x: x, y: 256 - h * 0.35), CGPoint(x: x + 52, y: 256 - h * 0.35), CGPoint(x: x + 26, y: 256 - h)], color: c)
                }
            }
        }
    }

    // MARK: - Item & achievement icons

    static func drawIcon(_ key: String) -> SKTexture {
        render(64, 64) { ctx, _ in
            round(ctx, rect: CGRect(x: 4, y: 4, width: 56, height: 56), radius: 14, color: UIColor(hex: "#1E2233"))
            ctx.setStrokeColor(UIColor(hex: "#3A4158").cgColor)
            ctx.setLineWidth(2)
            ctx.addPath(UIBezierPath(roundedRect: CGRect(x: 5, y: 5, width: 54, height: 54), cornerRadius: 13).cgPath)
            ctx.strokePath()
            switch key {
            case "sword":
                line(ctx, from: CGPoint(x: 20, y: 44), to: CGPoint(x: 44, y: 20), width: 6, color: UIColor(hex: "#DDE6F0"))
                line(ctx, from: CGPoint(x: 18, y: 40), to: CGPoint(x: 26, y: 48), width: 5, color: UIColor(hex: "#C9A227"))
            case "axe":
                line(ctx, from: CGPoint(x: 20, y: 46), to: CGPoint(x: 42, y: 22), width: 5, color: UIColor(hex: "#8A6D3B"))
                poly(ctx, points: [CGPoint(x: 42, y: 22), CGPoint(x: 52, y: 26), CGPoint(x: 46, y: 38), CGPoint(x: 36, y: 32)], color: UIColor(hex: "#B9C2D0"))
            case "blade":
                line(ctx, from: CGPoint(x: 22, y: 44), to: CGPoint(x: 44, y: 18), width: 4, color: UIColor(hex: "#7DF9FF"))
                line(ctx, from: CGPoint(x: 20, y: 42), to: CGPoint(x: 26, y: 48), width: 4, color: UIColor(hex: "#2C7A43"))
            case "staff":
                line(ctx, from: CGPoint(x: 22, y: 48), to: CGPoint(x: 40, y: 18), width: 5, color: UIColor(hex: "#6B4A2B"))
                circle(ctx, center: CGPoint(x: 41, y: 16), radius: 7, color: UIColor(hex: "#B45CFF"))
                circle(ctx, center: CGPoint(x: 41, y: 16), radius: 3.5, color: .white)
            case "bow":
                ctx.setStrokeColor(UIColor(hex: "#A97B4F").cgColor)
                ctx.setLineWidth(4)
                ctx.beginPath()
                ctx.addArc(center: CGPoint(x: 26, y: 32), radius: 16, startAngle: -1.2, endAngle: 1.2, clockwise: false)
                ctx.strokePath()
                line(ctx, from: CGPoint(x: 30, y: 17), to: CGPoint(x: 30, y: 47), width: 2, color: .white)
                line(ctx, from: CGPoint(x: 22, y: 32), to: CGPoint(x: 46, y: 32), width: 2, color: UIColor(hex: "#FF6B6B"))
            case "armor":
                round(ctx, rect: CGRect(x: 20, y: 16, width: 24, height: 32), radius: 8, color: UIColor(hex: "#7A8AA0"))
                fill(ctx, rect: CGRect(x: 20, y: 28, width: 24, height: 4), color: UIColor(hex: "#4E5A78"))
                circle(ctx, center: CGPoint(x: 32, y: 24), radius: 4, color: UIColor(hex: "#C9A227"))
            case "robe":
                poly(ctx, points: [CGPoint(x: 32, y: 12), CGPoint(x: 18, y: 50), CGPoint(x: 46, y: 50)], color: UIColor(hex: "#5B2E8F"))
                circle(ctx, center: CGPoint(x: 32, y: 30), radius: 5, color: UIColor(hex: "#B45CFF"))
            case "cloak":
                poly(ctx, points: [CGPoint(x: 18, y: 12), CGPoint(x: 46, y: 12), CGPoint(x: 40, y: 50), CGPoint(x: 24, y: 50)], color: UIColor(hex: "#2C7A43"))
            case "ring":
                ctx.setStrokeColor(UIColor(hex: "#FFD95E").cgColor)
                ctx.setLineWidth(6)
                ctx.beginPath()
                ctx.addArc(center: CGPoint(x: 32, y: 36), radius: 11, startAngle: 0, endAngle: 6.29, clockwise: false)
                ctx.strokePath()
                poly(ctx, points: [CGPoint(x: 26, y: 22), CGPoint(x: 38, y: 22), CGPoint(x: 32, y: 12)], color: UIColor(hex: "#7DF9FF"))
            case "amulet":
                line(ctx, from: CGPoint(x: 32, y: 10), to: CGPoint(x: 32, y: 26), width: 4, color: UIColor(hex: "#C9A227"))
                poly(ctx, points: [CGPoint(x: 32, y: 26), CGPoint(x: 42, y: 38), CGPoint(x: 32, y: 52), CGPoint(x: 22, y: 38)], color: UIColor(hex: "#FF4D6D"))
            case "charm":
                circle(ctx, center: CGPoint(x: 32, y: 32), radius: 14, color: UIColor(hex: "#3FA7F5"))
                circle(ctx, center: CGPoint(x: 32, y: 32), radius: 7, color: UIColor(hex: "#BFE9FF"))
            case "potion_hp":
                round(ctx, rect: CGRect(x: 24, y: 26, width: 16, height: 22), radius: 7, color: UIColor(hex: "#BFE9FF", alpha: 0.9))
                fill(ctx, rect: CGRect(x: 28, y: 14, width: 8, height: 12), color: UIColor(hex: "#8A6D3B"))
                ellipse(ctx, rect: CGRect(x: 26, y: 32, width: 12, height: 14), color: UIColor(hex: "#FF4D6D"))
            case "potion_mp":
                round(ctx, rect: CGRect(x: 24, y: 26, width: 16, height: 22), radius: 7, color: UIColor(hex: "#BFE9FF", alpha: 0.9))
                fill(ctx, rect: CGRect(x: 28, y: 14, width: 8, height: 12), color: UIColor(hex: "#8A6D3B"))
                ellipse(ctx, rect: CGRect(x: 26, y: 32, width: 12, height: 14), color: UIColor(hex: "#3FA7F5"))
            case "bomb":
                circle(ctx, center: CGPoint(x: 32, y: 36), radius: 13, color: UIColor(hex: "#2A2A33"))
                line(ctx, from: CGPoint(x: 38, y: 25), to: CGPoint(x: 44, y: 16), width: 3, color: UIColor(hex: "#8A6D3B"))
                circle(ctx, center: CGPoint(x: 45, y: 14), radius: 4, color: UIColor(hex: "#FFC46B"))
            case "gel":
                ellipse(ctx, rect: CGRect(x: 16, y: 24, width: 32, height: 24), color: UIColor(hex: "#58D68D"))
                circle(ctx, center: CGPoint(x: 25, y: 32), radius: 4, color: UIColor(hex: "#A9F5C3"))
            case "wing":
                poly(ctx, points: [CGPoint(x: 32, y: 48), CGPoint(x: 14, y: 16), CGPoint(x: 26, y: 44)], color: UIColor(hex: "#7B5FC9"))
                poly(ctx, points: [CGPoint(x: 32, y: 48), CGPoint(x: 50, y: 16), CGPoint(x: 38, y: 44)], color: UIColor(hex: "#7B5FC9"))
            case "bone":
                line(ctx, from: CGPoint(x: 16, y: 40), to: CGPoint(x: 48, y: 24), width: 6, color: UIColor(hex: "#E8E4D8"))
                circle(ctx, center: CGPoint(x: 15, y: 41), radius: 5, color: UIColor(hex: "#E8E4D8"))
                circle(ctx, center: CGPoint(x: 49, y: 23), radius: 5, color: UIColor(hex: "#E8E4D8"))
            case "ore":
                poly(ctx, points: [CGPoint(x: 16, y: 44), CGPoint(x: 24, y: 18), CGPoint(x: 42, y: 22), CGPoint(x: 46, y: 44)], color: UIColor(hex: "#6E6A85"))
                circle(ctx, center: CGPoint(x: 30, y: 34), radius: 4, color: UIColor(hex: "#7DF9FF"))
            case "relic":
                poly(ctx, points: [CGPoint(x: 32, y: 12), CGPoint(x: 44, y: 32), CGPoint(x: 32, y: 52), CGPoint(x: 20, y: 32)], color: UIColor(hex: "#C9A227"))
                poly(ctx, points: [CGPoint(x: 32, y: 20), CGPoint(x: 38, y: 32), CGPoint(x: 32, y: 44), CGPoint(x: 26, y: 32)], color: UIColor(hex: "#FFF3C4"))
            case "key":
                circle(ctx, center: CGPoint(x: 24, y: 32), radius: 9, color: UIColor(hex: "#FFD95E"))
                fill(ctx, rect: CGRect(x: 31, y: 30, width: 18, height: 4), color: UIColor(hex: "#FFD95E"))
                fill(ctx, rect: CGRect(x: 43, y: 30, width: 3, height: 10), color: UIColor(hex: "#FFD95E"))
            case "coins":
                ellipse(ctx, rect: CGRect(x: 18, y: 36, width: 28, height: 12), color: UIColor(hex: "#C9A227"))
                ellipse(ctx, rect: CGRect(x: 20, y: 28, width: 24, height: 12), color: UIColor(hex: "#FFD95E"))
                ellipse(ctx, rect: CGRect(x: 22, y: 20, width: 20, height: 12), color: UIColor(hex: "#FFF3C4"))
            case "scroll":
                round(ctx, rect: CGRect(x: 20, y: 12, width: 24, height: 40), radius: 6, color: UIColor(hex: "#E8DCC0"))
                fill(ctx, rect: CGRect(x: 25, y: 20, width: 14, height: 3), color: UIColor(hex: "#8A6D3B"))
                fill(ctx, rect: CGRect(x: 25, y: 27, width: 14, height: 3), color: UIColor(hex: "#8A6D3B"))
                fill(ctx, rect: CGRect(x: 25, y: 34, width: 10, height: 3), color: UIColor(hex: "#8A6D3B"))
            case "feather":
                ellipse(ctx, rect: CGRect(x: 24, y: 10, width: 14, height: 34), color: UIColor(hex: "#BFE9FF"))
                line(ctx, from: CGPoint(x: 31, y: 12), to: CGPoint(x: 31, y: 52), width: 2, color: UIColor(hex: "#3FA7F5"))
            case "shard":
                poly(ctx, points: [CGPoint(x: 32, y: 10), CGPoint(x: 42, y: 32), CGPoint(x: 36, y: 52), CGPoint(x: 28, y: 52), CGPoint(x: 22, y: 32)], color: UIColor(hex: "#7DF9FF"))
            case "meat":
                ellipse(ctx, rect: CGRect(x: 16, y: 22, width: 30, height: 24), color: UIColor(hex: "#B65A3B"))
                line(ctx, from: CGPoint(x: 38, y: 26), to: CGPoint(x: 50, y: 14), width: 5, color: UIColor(hex: "#E8E4D8"))
            case "skull":
                circle(ctx, center: CGPoint(x: 32, y: 28), radius: 13, color: UIColor(hex: "#E8E4D8"))
                round(ctx, rect: CGRect(x: 24, y: 34, width: 16, height: 12), radius: 4, color: UIColor(hex: "#E8E4D8"))
                circle(ctx, center: CGPoint(x: 27, y: 27), radius: 3.5, color: UIColor(hex: "#1A1A22"))
                circle(ctx, center: CGPoint(x: 37, y: 27), radius: 3.5, color: UIColor(hex: "#1A1A22"))
            case "crown":
                poly(ctx, points: [CGPoint(x: 16, y: 42), CGPoint(x: 16, y: 26), CGPoint(x: 24, y: 34), CGPoint(x: 32, y: 20), CGPoint(x: 40, y: 34), CGPoint(x: 48, y: 26), CGPoint(x: 48, y: 42)],
                     color: UIColor(hex: "#FFD95E"))
                circle(ctx, center: CGPoint(x: 32, y: 20), radius: 3, color: UIColor(hex: "#FF4D6D"))
            case "star":
                poly(ctx, points: [CGPoint(x: 32, y: 10), CGPoint(x: 37, y: 26), CGPoint(x: 54, y: 26), CGPoint(x: 40, y: 36), CGPoint(x: 45, y: 52), CGPoint(x: 32, y: 42), CGPoint(x: 19, y: 52), CGPoint(x: 24, y: 36), CGPoint(x: 10, y: 26), CGPoint(x: 27, y: 26)],
                     color: UIColor(hex: "#FFE66D"))
            case "sun":
                circle(ctx, center: CGPoint(x: 32, y: 32), radius: 11, color: UIColor(hex: "#FFC46B"))
                for i in 0..<8 {
                    let a = Double(i) * .pi / 4
                    line(ctx, from: CGPoint(x: 32 + cos(a) * 14, y: 32 + sin(a) * 14),
                         to: CGPoint(x: 32 + cos(a) * 19, y: 32 + sin(a) * 19), width: 3, color: UIColor(hex: "#FFC46B"))
                }
            case "ghost":
                round(ctx, rect: CGRect(x: 22, y: 14, width: 20, height: 28), radius: 9, color: UIColor(hex: "#BFE9FF"))
                poly(ctx, points: [CGPoint(x: 22, y: 36), CGPoint(x: 27, y: 48), CGPoint(x: 32, y: 36)], color: UIColor(hex: "#BFE9FF"))
                poly(ctx, points: [CGPoint(x: 32, y: 36), CGPoint(x: 37, y: 48), CGPoint(x: 42, y: 36)], color: UIColor(hex: "#BFE9FF"))
                circle(ctx, center: CGPoint(x: 28, y: 26), radius: 2.5, color: UIColor(hex: "#1A2A3A"))
                circle(ctx, center: CGPoint(x: 36, y: 26), radius: 2.5, color: UIColor(hex: "#1A2A3A"))
            case "dash":
                for i in 0..<3 {
                    poly(ctx, points: [CGPoint(x: 14 + CGFloat(i) * 12, y: 18), CGPoint(x: 24 + CGFloat(i) * 12, y: 32), CGPoint(x: 14 + CGFloat(i) * 12, y: 46)],
                         color: UIColor(hex: "#7DF9FF"))
                }
            case "golem":
                round(ctx, rect: CGRect(x: 18, y: 18, width: 28, height: 28), radius: 8, color: UIColor(hex: "#6E6A85"))
                circle(ctx, center: CGPoint(x: 27, y: 30), radius: 3.5, color: UIColor(hex: "#FF7B2E"))
                circle(ctx, center: CGPoint(x: 37, y: 30), radius: 3.5, color: UIColor(hex: "#FF7B2E"))
            case "knight":
                round(ctx, rect: CGRect(x: 20, y: 16, width: 24, height: 30), radius: 9, color: UIColor(hex: "#9AA3B2"))
                fill(ctx, rect: CGRect(x: 20, y: 28, width: 24, height: 5), color: UIColor(hex: "#1A1A22"))
                poly(ctx, points: [CGPoint(x: 28, y: 16), CGPoint(x: 36, y: 16), CGPoint(x: 32, y: 8)], color: UIColor(hex: "#FF5D5D"))
            case "dragon":
                ellipse(ctx, rect: CGRect(x: 14, y: 24, width: 36, height: 22), color: UIColor(hex: "#2E8F9E"))
                poly(ctx, points: [CGPoint(x: 40, y: 26), CGPoint(x: 36, y: 12), CGPoint(x: 46, y: 24)], color: UIColor(hex: "#F2E8C9"))
                circle(ctx, center: CGPoint(x: 40, y: 32), radius: 3, color: UIColor(hex: "#FFE66D"))
            case "chest":
                round(ctx, rect: CGRect(x: 14, y: 22, width: 36, height: 24), radius: 5, color: UIColor(hex: "#7A5230"))
                round(ctx, rect: CGRect(x: 14, y: 14, width: 36, height: 12), radius: 5, color: UIColor(hex: "#8F6538"))
                fill(ctx, rect: CGRect(x: 29, y: 14, width: 6, height: 32), color: UIColor(hex: "#C9A227"))
            default:
                round(ctx, rect: CGRect(x: 18, y: 22, width: 28, height: 24), radius: 6, color: UIColor(hex: "#8F6538"))
                fill(ctx, rect: CGRect(x: 18, y: 30, width: 28, height: 4), color: UIColor(hex: "#5A3A22"))
            }
        }
    }
}

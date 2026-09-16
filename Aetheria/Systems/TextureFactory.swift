import UIKit
import SpriteKit

/// Procedural sprite factory: every texture in the game is drawn in code with
/// CoreGraphics and cached. No image assets required (except the App Icon).
enum TextureFactory {
    private static var cache: [String: SKTexture] = [:]

    static func get(_ key: String) -> SKTexture {
        if let t = cache[key] { return t }
        let t = build(key)
        cache[key] = t
        return t
    }

    static func preloadEssential() {
        for c in ["knight", "ranger", "mage"] {
            for p in ["idle", "run", "jump", "fall", "attack", "dash", "climb"] {
                for f in 0..<framesFor(pose: p) { _ = get("player_\(c)_\(p)_\(f)") }
            }
        }
        for key in ["slime", "bat", "skeleton", "orc", "ghost", "mage"] {
            for f in 0..<3 { _ = get("enemy_\(key)_\(f)") }
        }
        for key in ["coin_0", "heart", "mana", "itemGlow", "chest_0", "chest_1",
                    "flag_0", "flag_1", "sign", "ladder", "key",
                    "tile_grass", "tile_dirt", "tile_stone", "tile_cave",
                    "tile_castle", "tile_cloud", "tile_wood",
                    "spikes", "lava_0", "lava_1",
                    "arrow", "fireball_0", "bolt", "bone", "slimeball", "rock",
                    "slash_0", "slash_1", "slash_2", "spark", "glow", "shadow",
                    "puff_0", "puff_1", "rain", "snow", "ash", "leaf"] {
            _ = get(key)
        }
        for f in 0..<4 { _ = get("portal_\(f)"); _ = get("boom_\(f)") }
        for theme in ["forest", "caves", "castle", "sky"] {
            for b in 0..<4 { _ = get("sky_\(theme)_\(b)") }
            for layer in 0..<3 { _ = get("par_\(theme)_\(layer)") }
        }
    }

    static func framesFor(pose: String) -> Int {
        switch pose {
        case "idle": return 2
        case "run": return 4
        case "attack": return 3
        case "climb": return 2
        default: return 1
        }
    }

    // MARK: - Dispatcher

    private static func build(_ key: String) -> SKTexture {
        let parts = key.split(separator: "_").map(String.init)
        if parts.first == "player", parts.count >= 4 {
            let frame = Int(parts.last ?? "0") ?? 0
            let pose = parts[2]
            return drawPlayer(classId: parts[1], pose: pose, frame: frame)
        }
        if parts.first == "enemy", parts.count >= 3 {
            return drawEnemy(id: parts[1], frame: Int(parts[2]) ?? 0)
        }
        if parts.first == "boss", parts.count >= 3 {
            return drawBoss(id: "boss_\(parts[1])", frame: Int(parts[2]) ?? 0)
        }
        if parts.first == "npc", parts.count >= 2 {
            return drawNPC(id: parts[1])
        }
        if parts.first == "icon", parts.count >= 2 {
            return drawIcon(parts[1])
        }
        if parts.first == "sky", parts.count >= 3 {
            return drawSky(theme: parts[1], bucket: Int(parts[2]) ?? 2)
        }
        if parts.first == "par", parts.count >= 3 {
            return drawParallax(theme: parts[1], layer: Int(parts[2]) ?? 0)
        }
        switch key {
        case "tile_grass": return drawTile(base: "#5A3A22", top: "#3FD97C", style: .grass)
        case "tile_dirt": return drawTile(base: "#5A3A22", top: nil, style: .speckle)
        case "tile_stone": return drawTile(base: "#6B7280", top: nil, style: .brick)
        case "tile_cave": return drawTile(base: "#3B3350", top: "#57507A", style: .crack)
        case "tile_castle": return drawTile(base: "#4E5A78", top: "#8B9CC9", style: .brick)
        case "tile_cloud": return drawCloudTile()
        case "tile_wood": return drawTile(base: "#7A5230", top: "#A97B4F", style: .plank)
        case "spikes": return drawSpikes()
        case "lava_0": return drawLava(frame: 0)
        case "lava_1": return drawLava(frame: 1)
        case "coin_0": return drawCoin()
        case "heart": return drawHeart()
        case "mana": return drawMana()
        case "itemGlow": return drawItemGlow()
        case "key": return drawKey()
        case "chest_0": return drawChest(open: false)
        case "chest_1": return drawChest(open: true)
        case "flag_0": return drawFlag(active: false)
        case "flag_1": return drawFlag(active: true)
        case "sign": return drawSign()
        case "ladder": return drawLadder()
        case "portal_0", "portal_1", "portal_2", "portal_3":
            return drawPortal(frame: Int(key.suffix(1)) ?? 0)
        case "arrow": return drawArrow(color: "#E8E4D8")
        case "arrow_red": return drawArrow(color: "#FF6B6B")
        case "fireball_0": return drawFireball(frame: 0)
        case "fireball_1": return drawFireball(frame: 1)
        case "bolt": return drawBolt()
        case "bone": return drawBone()
        case "slimeball": return drawSlimeball()
        case "rock": return drawRock()
        case "slash_0", "slash_1", "slash_2": return drawSlash(frame: Int(key.suffix(1)) ?? 0)
        case "boom_0", "boom_1", "boom_2", "boom_3": return drawBoom(frame: Int(key.suffix(1)) ?? 0)
        case "spark": return drawSpark()
        case "glow": return drawGlow()
        case "shadow": return drawShadow()
        case "puff_0": return drawPuff(frame: 0)
        case "puff_1": return drawPuff(frame: 1)
        case "rain": return drawStreak(color: "#7FB5FF")
        case "snow": return drawDot(color: "#FFFFFF", r: 5)
        case "ash": return drawDot(color: "#B9B3A8", r: 4)
        case "leaf": return drawLeaf()
        case "torch_0": return drawTorch(frame: 0)
        case "torch_1": return drawTorch(frame: 1)
        case "crystal": return drawCrystal()
        case "tree": return drawTree()
        case "bush": return drawBush()
        case "rockDeco": return drawRockDeco()
        case "tuft": return drawTuft()
        case "mushroom": return drawMushroom()
        case "banner": return drawBanner()
        case "cloudDeco": return drawCloudDeco()
        case "stalactite": return drawStalactite()
        case "pillar": return drawPillar()
        case "telegraph": return drawTelegraph()
        default: return drawMissing()
        }
    }

    // MARK: - Core helpers

    static func render(_ w: CGFloat, _ h: CGFloat, _ draw: (CGContext, CGRect) -> Void) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { ctx in
            draw(ctx.cgContext, CGRect(x: 0, y: 0, width: w, height: h))
        }
        let tex = SKTexture(image: image)
        tex.filteringMode = .nearest
        return tex
    }

    static func fill(_ ctx: CGContext, rect: CGRect, color: UIColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
    }

    static func ellipse(_ ctx: CGContext, rect: CGRect, color: UIColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: rect)
    }

    static func round(_ ctx: CGContext, rect: CGRect, radius: CGFloat, color: UIColor) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        color.setFill()
        path.fill()
    }

    static func poly(_ ctx: CGContext, points: [CGPoint], color: UIColor) {
        guard points.count > 2 else { return }
        ctx.setFillColor(color.cgColor)
        ctx.beginPath()
        ctx.move(to: points[0])
        for p in points.dropFirst() { ctx.addLine(to: p) }
        ctx.closePath()
        ctx.fillPath()
    }

    static func line(_ ctx: CGContext, from: CGPoint, to: CGPoint, width: CGFloat, color: UIColor) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.setLineCap(.round)
        ctx.beginPath()
        ctx.move(to: from)
        ctx.addLine(to: to)
        ctx.strokePath()
    }

    static func circle(_ ctx: CGContext, center: CGPoint, radius: CGFloat, color: UIColor) {
        ellipse(ctx, rect: CGRect(x: center.x - radius, y: center.y - radius,
                                  width: radius * 2, height: radius * 2), color: color)
    }

    // MARK: - Player

    private static func drawPlayer(classId: String, pose: String, frame: Int) -> SKTexture {
        render(56, 76) { ctx, r in
            let accent: UIColor
            switch classId {
            case "ranger": accent = UIColor(hex: "#3FD97C")
            case "mage": accent = UIColor(hex: "#B45CFF")
            default: accent = UIColor(hex: "#4DA3FF")
            }
            let skin = UIColor(hex: "#F2C89B")
            let dark = UIColor(hex: "#23232E")
            let cloth = accent.darkened(0.55)
            var bob: CGFloat = 0
            var legA: CGFloat = 0, legB: CGFloat = 0
            var armAngle: CGFloat = -0.5
            var lean: CGFloat = 0
            var weaponOut = true
            switch pose {
            case "idle":
                bob = frame == 0 ? 0 : 2
            case "run":
                let steps: [(CGFloat, CGFloat)] = [(7, -7), (3, 0), (-7, 7), (-3, 0)]
                legA = steps[frame % 4].0; legB = steps[frame % 4].1
                bob = frame % 2 == 0 ? 0 : 2
                lean = 3
                armAngle = -0.5 + CGFloat(frame) * 0.15
            case "jump":
                legA = -9; legB = -5; armAngle = -1.4
            case "fall":
                legA = 5; legB = 8; armAngle = 0.6
            case "attack":
                armAngle = [-0.9, 0.35, 1.2][min(frame, 2)]
                lean = [0, 4, 7][min(frame, 2)]
                legA = 6; legB = -4
            case "dash":
                lean = 10; legA = -6; legB = 8; bob = 4
            case "climb":
                legA = frame == 0 ? -5 : 5; legB = -legA; armAngle = -2.2; weaponOut = false
            default: break
            }
            let cx = r.midX + lean
            // Legs
            round(ctx, rect: CGRect(x: cx - 11 + legA * 0.4, y: 52 + bob - max(0, -legA * 0.3), width: 9, height: 20), radius: 4, color: dark)
            round(ctx, rect: CGRect(x: cx + 2 + legB * 0.4, y: 52 + bob - max(0, -legB * 0.3), width: 9, height: 20), radius: 4, color: dark.darkened(0.8))
            // Boots
            round(ctx, rect: CGRect(x: cx - 12 + legA * 0.4, y: 66 + bob, width: 11, height: 7), radius: 3, color: UIColor(hex: "#17171F"))
            round(ctx, rect: CGRect(x: cx + 1 + legB * 0.4, y: 66 + bob, width: 11, height: 7), radius: 3, color: UIColor(hex: "#17171F"))
            // Torso
            round(ctx, rect: CGRect(x: cx - 13, y: 30 + bob, width: 26, height: 26), radius: 8, color: cloth)
            fill(ctx, rect: CGRect(x: cx - 13, y: 46 + bob, width: 26, height: 5), color: UIColor(hex: "#17171F"))
            circle(ctx, center: CGPoint(x: cx, y: 48.5 + bob), radius: 3, color: UIColor(hex: "#FFD166"))
            // Head
            circle(ctx, center: CGPoint(x: cx, y: 20 + bob), radius: 12, color: skin)
            circle(ctx, center: CGPoint(x: cx + 4, y: 19 + bob), radius: 2.2, color: dark)
            // Class headgear
            switch classId {
            case "knight":
                round(ctx, rect: CGRect(x: cx - 13, y: 2 + bob, width: 26, height: 14), radius: 6, color: UIColor(hex: "#9AA3B2"))
                fill(ctx, rect: CGRect(x: cx - 13, y: 12 + bob, width: 26, height: 3), color: dark)
                poly(ctx, points: [CGPoint(x: cx - 4, y: 2 + bob), CGPoint(x: cx + 4, y: 2 + bob), CGPoint(x: cx, y: -6 + bob)], color: UIColor(hex: "#FF5D5D"))
            case "ranger":
                poly(ctx, points: [CGPoint(x: cx - 13, y: 16 + bob), CGPoint(x: cx + 13, y: 16 + bob), CGPoint(x: cx + 2, y: -4 + bob)], color: UIColor(hex: "#2C7A43"))
            default:
                fill(ctx, rect: CGRect(x: cx - 15, y: 12 + bob, width: 30, height: 5), color: UIColor(hex: "#5B2E8F"))
                poly(ctx, points: [CGPoint(x: cx - 11, y: 13 + bob), CGPoint(x: cx + 11, y: 13 + bob), CGPoint(x: cx + 6, y: -8 + bob)], color: UIColor(hex: "#7A3FC9"))
                circle(ctx, center: CGPoint(x: cx + 6, y: -6 + bob), radius: 2.5, color: UIColor(hex: "#FFE66D"))
            }
            // Arm + weapon
            if weaponOut {
                let hx = cx + 12, hy = 38 + bob
                let ex = hx + cos(armAngle) * 14, ey = hy + sin(armAngle) * 14
                line(ctx, from: CGPoint(x: hx, y: hy), to: CGPoint(x: ex, y: ey), width: 7, color: cloth.lightened(0.15))
                circle(ctx, center: CGPoint(x: ex, y: ey), radius: 4, color: skin)
                if classId == "mage" {
                    line(ctx, from: CGPoint(x: ex - 8, y: ey + 14), to: CGPoint(x: ex + 8, y: ey - 14), width: 4, color: UIColor(hex: "#6B4A2B"))
                    circle(ctx, center: CGPoint(x: ex + 9, y: ey - 16), radius: 5, color: UIColor(hex: "#7DF9FF"))
                } else {
                    let tipX = ex + cos(armAngle - 0.4) * 26, tipY = ey + sin(armAngle - 0.4) * 26
                    line(ctx, from: CGPoint(x: ex, y: ey), to: CGPoint(x: tipX, y: tipY), width: 5, color: UIColor(hex: "#DDE6F0"))
                    line(ctx, from: CGPoint(x: ex - cos(armAngle + 1.57) * 6, y: ey - sin(armAngle + 1.57) * 6),
                         to: CGPoint(x: ex + cos(armAngle + 1.57) * 6, y: ey + sin(armAngle + 1.57) * 6), width: 4, color: UIColor(hex: "#8A6D3B"))
                }
            } else {
                line(ctx, from: CGPoint(x: cx + 10, y: 36 + bob), to: CGPoint(x: cx + 14, y: 24 + bob), width: 7, color: cloth.lightened(0.15))
                line(ctx, from: CGPoint(x: cx - 10, y: 36 + bob), to: CGPoint(x: cx - 14, y: 26 + bob), width: 7, color: cloth)
            }
            if pose == "dash" {
                ctx.setStrokeColor(UIColor(hex: "#FFFFFF", alpha: 0.4).cgColor)
                ctx.setLineWidth(3)
                for i in 0..<3 {
                    ctx.beginPath()
                    ctx.move(to: CGPoint(x: cx - 16, y: 30 + CGFloat(i) * 10 + bob))
                    ctx.addLine(to: CGPoint(x: cx - 34, y: 30 + CGFloat(i) * 10 + bob))
                    ctx.strokePath()
                }
            }
        }
    }

    // MARK: - Enemies

    private static func drawEnemy(id: String, frame: Int) -> SKTexture {
        switch id {
        case "slime": return render(60, 48) { ctx, r in
            let squash: CGFloat = frame == 1 ? 6 : 0
            ellipse(ctx, rect: CGRect(x: 6 - squash / 2, y: 12 + squash, width: 48 + squash, height: 30 - squash), color: UIColor(hex: "#58D68D"))
            ellipse(ctx, rect: CGRect(x: 14 - squash / 2, y: 16 + squash, width: 16, height: 10), color: UIColor(hex: "#A9F5C3", alpha: 0.8))
            circle(ctx, center: CGPoint(x: 23, y: 30), radius: 4, color: .white)
            circle(ctx, center: CGPoint(x: 37, y: 30), radius: 4, color: .white)
            circle(ctx, center: CGPoint(x: 24, y: 31), radius: 2, color: UIColor(hex: "#1A1A22"))
            circle(ctx, center: CGPoint(x: 38, y: 31), radius: 2, color: UIColor(hex: "#1A1A22"))
        }
        case "bat": return render(64, 48) { ctx, _ in
            let up = frame != 1
            let wing = UIColor(hex: "#7B5FC9")
            if up {
                poly(ctx, points: [CGPoint(x: 32, y: 30), CGPoint(x: 4, y: 6), CGPoint(x: 14, y: 34)], color: wing)
                poly(ctx, points: [CGPoint(x: 32, y: 30), CGPoint(x: 60, y: 6), CGPoint(x: 50, y: 34)], color: wing)
            } else {
                poly(ctx, points: [CGPoint(x: 32, y: 22), CGPoint(x: 6, y: 44), CGPoint(x: 16, y: 20)], color: wing)
                poly(ctx, points: [CGPoint(x: 32, y: 22), CGPoint(x: 58, y: 44), CGPoint(x: 48, y: 20)], color: wing)
            }
            poly(ctx, points: [CGPoint(x: 24, y: 22), CGPoint(x: 28, y: 12), CGPoint(x: 32, y: 22)], color: wing.darkened())
            poly(ctx, points: [CGPoint(x: 40, y: 22), CGPoint(x: 36, y: 12), CGPoint(x: 32, y: 22)], color: wing.darkened())
            circle(ctx, center: CGPoint(x: 32, y: 28), radius: 11, color: UIColor(hex: "#4A3A8F"))
            circle(ctx, center: CGPoint(x: 28, y: 27), radius: 2.5, color: UIColor(hex: "#FF4D4D"))
            circle(ctx, center: CGPoint(x: 36, y: 27), radius: 2.5, color: UIColor(hex: "#FF4D4D"))
        }
        case "skeleton": return render(52, 78) { ctx, _ in
            let bone = UIColor(hex: "#E8E4D8")
            let legOff: CGFloat = frame == 0 ? 4 : (frame == 1 ? -4 : 0)
            line(ctx, from: CGPoint(x: 22, y: 52), to: CGPoint(x: 22 + legOff, y: 72), width: 5, color: bone.darkened(0.85))
            line(ctx, from: CGPoint(x: 30, y: 52), to: CGPoint(x: 30 - legOff, y: 72), width: 5, color: bone.darkened(0.85))
            line(ctx, from: CGPoint(x: 26, y: 50), to: CGPoint(x: 26, y: 32), width: 6, color: bone)
            for i in 0..<3 {
                line(ctx, from: CGPoint(x: 18, y: 36 + CGFloat(i) * 6), to: CGPoint(x: 34, y: 36 + CGFloat(i) * 6), width: 3, color: bone.darkened(0.9))
            }
            circle(ctx, center: CGPoint(x: 26, y: 22), radius: 11, color: bone)
            circle(ctx, center: CGPoint(x: 22, y: 21), radius: 3, color: UIColor(hex: "#1A1A22"))
            circle(ctx, center: CGPoint(x: 30, y: 21), radius: 3, color: UIColor(hex: "#1A1A22"))
            round(ctx, rect: CGRect(x: 22, y: 27, width: 8, height: 4), radius: 2, color: UIColor(hex: "#1A1A22"))
            // Bow
            ctx.setStrokeColor(UIColor(hex: "#6B4A2B").cgColor)
            ctx.setLineWidth(3)
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: 44, y: 40), radius: 12, startAngle: -1.1, endAngle: 1.1, clockwise: false)
            ctx.strokePath()
            line(ctx, from: CGPoint(x: 44, y: 28), to: CGPoint(x: 44, y: 52), width: 1.5, color: UIColor(hex: "#CCCCCC"))
            if frame == 2 {
                line(ctx, from: CGPoint(x: 30, y: 40), to: CGPoint(x: 52, y: 40), width: 2, color: UIColor(hex: "#FF6B6B"))
            }
        }
        case "orc": return render(72, 92) { ctx, _ in
            let skin = UIColor(hex: "#4E9B47")
            let legOff: CGFloat = frame == 0 ? 5 : (frame == 1 ? -5 : 0)
            round(ctx, rect: CGRect(x: 20 + legOff, y: 64, width: 13, height: 24), radius: 6, color: skin.darkened(0.7))
            round(ctx, rect: CGRect(x: 39 - legOff, y: 64, width: 13, height: 24), radius: 6, color: skin.darkened(0.7))
            round(ctx, rect: CGRect(x: 14, y: 30, width: 44, height: 38), radius: 12, color: skin)
            round(ctx, rect: CGRect(x: 14, y: 52, width: 44, height: 8), radius: 4, color: UIColor(hex: "#3A2A1A"))
            circle(ctx, center: CGPoint(x: 36, y: 20), radius: 14, color: skin)
            poly(ctx, points: [CGPoint(x: 22, y: 18), CGPoint(x: 12, y: 12), CGPoint(x: 23, y: 10)], color: skin)
            poly(ctx, points: [CGPoint(x: 50, y: 18), CGPoint(x: 60, y: 12), CGPoint(x: 49, y: 10)], color: skin)
            circle(ctx, center: CGPoint(x: 30, y: 19), radius: 3, color: UIColor(hex: "#FFE66D"))
            circle(ctx, center: CGPoint(x: 42, y: 19), radius: 3, color: UIColor(hex: "#FFE66D"))
            poly(ctx, points: [CGPoint(x: 28, y: 28), CGPoint(x: 31, y: 28), CGPoint(x: 29.5, y: 23)], color: .white)
            poly(ctx, points: [CGPoint(x: 41, y: 28), CGPoint(x: 44, y: 28), CGPoint(x: 42.5, y: 23)], color: .white)
            // Club
            if frame == 2 {
                line(ctx, from: CGPoint(x: 56, y: 44), to: CGPoint(x: 66, y: 12), width: 10, color: UIColor(hex: "#6B4A2B"))
                circle(ctx, center: CGPoint(x: 66, y: 10), radius: 8, color: UIColor(hex: "#6B4A2B"))
            } else {
                line(ctx, from: CGPoint(x: 56, y: 44), to: CGPoint(x: 64, y: 66), width: 10, color: UIColor(hex: "#6B4A2B"))
                circle(ctx, center: CGPoint(x: 64, y: 68), radius: 8, color: UIColor(hex: "#6B4A2B"))
            }
        }
        case "ghost": return render(56, 78) { ctx, _ in
            let g = UIColor(hex: "#BFE9FF", alpha: 0.9)
            let bob: CGFloat = frame == 1 ? -4 : 0
            round(ctx, rect: CGRect(x: 10, y: 8 + bob, width: 36, height: 52), radius: 16, color: g)
            poly(ctx, points: [CGPoint(x: 10, y: 52 + bob), CGPoint(x: 18, y: 70 + bob), CGPoint(x: 26, y: 52 + bob)], color: g)
            poly(ctx, points: [CGPoint(x: 26, y: 52 + bob), CGPoint(x: 34, y: 70 + bob), CGPoint(x: 42, y: 52 + bob)], color: g)
            poly(ctx, points: [CGPoint(x: 38, y: 52 + bob), CGPoint(x: 46, y: 66 + bob), CGPoint(x: 50, y: 52 + bob)], color: g)
            ellipse(ctx, rect: CGRect(x: 19, y: 26 + bob, width: 7, height: 10), color: UIColor(hex: "#1A2A3A"))
            ellipse(ctx, rect: CGRect(x: 30, y: 26 + bob, width: 7, height: 10), color: UIColor(hex: "#1A2A3A"))
            ellipse(ctx, rect: CGRect(x: 24, y: 42 + bob, width: 8, height: 10), color: UIColor(hex: "#1A2A3A"))
        }
        case "mage": return render(56, 82) { ctx, _ in
            let robe = UIColor(hex: "#3A2A5E")
            poly(ctx, points: [CGPoint(x: 28, y: 20), CGPoint(x: 8, y: 76), CGPoint(x: 48, y: 76)], color: robe)
            circle(ctx, center: CGPoint(x: 28, y: 24), radius: 9, color: UIColor(hex: "#C9A6F2"))
            circle(ctx, center: CGPoint(x: 25, y: 23), radius: 2, color: UIColor(hex: "#FF4D6D"))
            circle(ctx, center: CGPoint(x: 31, y: 23), radius: 2, color: UIColor(hex: "#FF4D6D"))
            poly(ctx, points: [CGPoint(x: 14, y: 18), CGPoint(x: 42, y: 18), CGPoint(x: 34, y: -6)], color: UIColor(hex: "#241A3E"))
            line(ctx, from: CGPoint(x: 46, y: 74), to: CGPoint(x: 46, y: 30), width: 4, color: UIColor(hex: "#6B4A2B"))
            let orbR: CGFloat = frame == 2 ? 8 : 5
            circle(ctx, center: CGPoint(x: 46, y: 26), radius: orbR + 3, color: UIColor(hex: "#B45CFF", alpha: 0.35))
            circle(ctx, center: CGPoint(x: 46, y: 26), radius: orbR, color: UIColor(hex: "#E0A6FF"))
        }
        default: return drawMissing()
        }
    }

    // MARK: - Bosses

    private static func drawBoss(id: String, frame: Int) -> SKTexture {
        switch id {
        case "boss_golem": return render(160, 180) { ctx, _ in
            let rock = UIColor(hex: "#6E6A85")
            let slam = frame == 2
            let armY: CGFloat = slam ? 120 : 60
            // Legs
            round(ctx, rect: CGRect(x: 48, y: 128, width: 26, height: 48), radius: 8, color: rock.darkened(0.7))
            round(ctx, rect: CGRect(x: 86, y: 128, width: 26, height: 48), radius: 8, color: rock.darkened(0.7))
            // Torso
            round(ctx, rect: CGRect(x: 36, y: 60, width: 88, height: 76), radius: 14, color: rock)
            round(ctx, rect: CGRect(x: 48, y: 72, width: 64, height: 20), radius: 8, color: rock.darkened(0.8))
            // Core
            circle(ctx, center: CGPoint(x: 80, y: 108), radius: slam ? 16 : 12, color: UIColor(hex: "#FF7B2E", alpha: 0.4))
            circle(ctx, center: CGPoint(x: 80, y: 108), radius: slam ? 10 : 7, color: UIColor(hex: "#FFC46B"))
            // Head
            round(ctx, rect: CGRect(x: 60, y: 26, width: 40, height: 36), radius: 8, color: rock.darkened(0.85))
            circle(ctx, center: CGPoint(x: 71, y: 42), radius: 4, color: UIColor(hex: "#FF7B2E"))
            circle(ctx, center: CGPoint(x: 89, y: 42), radius: 4, color: UIColor(hex: "#FF7B2E"))
            // Moss
            circle(ctx, center: CGPoint(x: 50, y: 70), radius: 6, color: UIColor(hex: "#3FD97C", alpha: 0.7))
            circle(ctx, center: CGPoint(x: 112, y: 96), radius: 8, color: UIColor(hex: "#3FD97C", alpha: 0.7))
            // Arms
            let ax: CGFloat = slam ? 30 : 14
            round(ctx, rect: CGRect(x: ax, y: armY - 30, width: 24, height: 70), radius: 10, color: rock.darkened(0.8))
            round(ctx, rect: CGRect(x: 160 - ax - 24, y: armY - 30, width: 24, height: 70), radius: 10, color: rock.darkened(0.8))
            circle(ctx, center: CGPoint(x: ax + 12, y: armY + 44), radius: 15, color: rock.darkened(0.65))
            circle(ctx, center: CGPoint(x: 160 - ax - 12, y: armY + 44), radius: 15, color: rock.darkened(0.65))
        }
        case "boss_knight": return render(100, 132) { ctx, _ in
            let armor = UIColor(hex: "#2E2E3E")
            let trim = UIColor(hex: "#C9A227")
            let atk = frame == 2
            round(ctx, rect: CGRect(x: 32, y: 88, width: 14, height: 40), radius: 6, color: armor.darkened(0.7))
            round(ctx, rect: CGRect(x: 54, y: 88, width: 14, height: 40), radius: 6, color: armor.darkened(0.7))
            round(ctx, rect: CGRect(x: 26, y: 44, width: 48, height: 50), radius: 10, color: armor)
            line(ctx, from: CGPoint(x: 50, y: 48), to: CGPoint(x: 50, y: 90), width: 4, color: trim)
            circle(ctx, center: CGPoint(x: 50, y: 34), radius: 16, color: armor)
            round(ctx, rect: CGRect(x: 38, y: 28, width: 24, height: 6), radius: 3, color: UIColor(hex: "#FF3B3B"))
            poly(ctx, points: [CGPoint(x: 44, y: 18), CGPoint(x: 56, y: 18), CGPoint(x: 50, y: 2)], color: UIColor(hex: "#FF3B3B"))
            if atk {
                line(ctx, from: CGPoint(x: 72, y: 60), to: CGPoint(x: 96, y: 96), width: 8, color: UIColor(hex: "#DDE6F0"))
                line(ctx, from: CGPoint(x: 20, y: 100), to: CGPoint(x: 90, y: 60), width: 4, color: UIColor(hex: "#FF3B3B", alpha: 0.7))
            } else {
                line(ctx, from: CGPoint(x: 72, y: 60), to: CGPoint(x: 78, y: 14), width: 8, color: UIColor(hex: "#DDE6F0"))
            }
        }
        case "boss_dragon": return render(200, 160) { ctx, _ in
            let body = UIColor(hex: "#2E8F9E")
            let up = frame != 1
            if up {
                poly(ctx, points: [CGPoint(x: 100, y: 90), CGPoint(x: 20, y: 10), CGPoint(x: 45, y: 95)], color: body.darkened(0.7))
                poly(ctx, points: [CGPoint(x: 100, y: 90), CGPoint(x: 180, y: 10), CGPoint(x: 155, y: 95)], color: body.darkened(0.7))
            } else {
                poly(ctx, points: [CGPoint(x: 100, y: 80), CGPoint(x: 10, y: 120), CGPoint(x: 50, y: 80)], color: body.darkened(0.7))
                poly(ctx, points: [CGPoint(x: 100, y: 80), CGPoint(x: 190, y: 120), CGPoint(x: 150, y: 80)], color: body.darkened(0.7))
            }
            poly(ctx, points: [CGPoint(x: 60, y: 100), CGPoint(x: 10, y: 140), CGPoint(x: 55, y: 115)], color: body.darkened(0.8))
            ellipse(ctx, rect: CGRect(x: 55, y: 70, width: 95, height: 55), color: body)
            ellipse(ctx, rect: CGRect(x: 70, y: 85, width: 60, height: 30), color: body.lightened(0.3))
            circle(ctx, center: CGPoint(x: 155, y: 75), radius: 20, color: body)
            poly(ctx, points: [CGPoint(x: 145, y: 58), CGPoint(x: 138, y: 40), CGPoint(x: 152, y: 56)], color: UIColor(hex: "#F2E8C9"))
            poly(ctx, points: [CGPoint(x: 160, y: 57), CGPoint(x: 160, y: 38), CGPoint(x: 167, y: 56)], color: UIColor(hex: "#F2E8C9"))
            circle(ctx, center: CGPoint(x: 160, y: 72), radius: 4, color: UIColor(hex: "#FFE66D"))
            if frame == 2 {
                poly(ctx, points: [CGPoint(x: 172, y: 82), CGPoint(x: 198, y: 74), CGPoint(x: 198, y: 92)], color: UIColor(hex: "#FF7B2E"))
                circle(ctx, center: CGPoint(x: 190, y: 83), radius: 6, color: UIColor(hex: "#FFE66D"))
            }
        }
        default: return drawMissing()
        }
    }

    // MARK: - NPCs

    private static func drawNPC(id: String) -> SKTexture {
        render(56, 82) { ctx, _ in
            let skin = UIColor(hex: "#F2C89B")
            switch id {
            case "elder":
                poly(ctx, points: [CGPoint(x: 28, y: 28), CGPoint(x: 10, y: 78), CGPoint(x: 46, y: 78)], color: UIColor(hex: "#4E5A78"))
                circle(ctx, center: CGPoint(x: 28, y: 24), radius: 10, color: skin)
                poly(ctx, points: [CGPoint(x: 20, y: 28), CGPoint(x: 36, y: 28), CGPoint(x: 28, y: 52)], color: UIColor(hex: "#DDDDDD"))
                line(ctx, from: CGPoint(x: 46, y: 76), to: CGPoint(x: 46, y: 30), width: 4, color: UIColor(hex: "#6B4A2B"))
                circle(ctx, center: CGPoint(x: 46, y: 27), radius: 4, color: UIColor(hex: "#9AD7FF"))
            case "merchant":
                round(ctx, rect: CGRect(x: 14, y: 32, width: 28, height: 44), radius: 10, color: UIColor(hex: "#8A5A3B"))
                round(ctx, rect: CGRect(x: 18, y: 44, width: 20, height: 30), radius: 6, color: UIColor(hex: "#C9A227"))
                circle(ctx, center: CGPoint(x: 28, y: 24), radius: 10, color: skin)
                fill(ctx, rect: CGRect(x: 14, y: 16, width: 28, height: 5), color: UIColor(hex: "#5A3A22"))
                round(ctx, rect: CGRect(x: 18, y: 4, width: 20, height: 13), radius: 4, color: UIColor(hex: "#5A3A22"))
                circle(ctx, center: CGPoint(x: 48, y: 62), radius: 9, color: UIColor(hex: "#A97B4F"))
                line(ctx, from: CGPoint(x: 48, y: 53), to: CGPoint(x: 48, y: 48), width: 3, color: UIColor(hex: "#5A3A22"))
            case "hermit":
                poly(ctx, points: [CGPoint(x: 28, y: 14), CGPoint(x: 10, y: 78), CGPoint(x: 46, y: 78)], color: UIColor(hex: "#3A3A4E"))
                circle(ctx, center: CGPoint(x: 28, y: 30), radius: 8, color: skin.darkened(0.9))
                round(ctx, rect: CGRect(x: 44, y: 44, width: 10, height: 14), radius: 3, color: UIColor(hex: "#2A2A33"))
                circle(ctx, center: CGPoint(x: 49, y: 51), radius: 3.5, color: UIColor(hex: "#FFC46B"))
            case "guard":
                round(ctx, rect: CGRect(x: 18, y: 58, width: 9, height: 20), radius: 4, color: UIColor(hex: "#23232E"))
                round(ctx, rect: CGRect(x: 30, y: 58, width: 9, height: 20), radius: 4, color: UIColor(hex: "#23232E"))
                round(ctx, rect: CGRect(x: 15, y: 32, width: 27, height: 28), radius: 8, color: UIColor(hex: "#7A8AA0"))
                circle(ctx, center: CGPoint(x: 28, y: 23), radius: 10, color: skin)
                round(ctx, rect: CGRect(x: 17, y: 8, width: 22, height: 12), radius: 5, color: UIColor(hex: "#9AA3B2"))
                line(ctx, from: CGPoint(x: 47, y: 78), to: CGPoint(x: 47, y: 10), width: 4, color: UIColor(hex: "#6B4A2B"))
                poly(ctx, points: [CGPoint(x: 43, y: 10), CGPoint(x: 51, y: 10), CGPoint(x: 47, y: 0)], color: UIColor(hex: "#DDE6F0"))
            default: // spirit
                round(ctx, rect: CGRect(x: 14, y: 12, width: 28, height: 46), radius: 13, color: UIColor(hex: "#7DF9FF", alpha: 0.75))
                poly(ctx, points: [CGPoint(x: 14, y: 50), CGPoint(x: 28, y: 74), CGPoint(x: 42, y: 50)], color: UIColor(hex: "#7DF9FF", alpha: 0.75))
                circle(ctx, center: CGPoint(x: 23, y: 30), radius: 3, color: UIColor(hex: "#0A2A3A"))
                circle(ctx, center: CGPoint(x: 33, y: 30), radius: 3, color: UIColor(hex: "#0A2A3A"))
            }
        }
    }

    static func drawMissing() -> SKTexture {
        render(32, 32) { ctx, r in
            fill(ctx, rect: r, color: UIColor(hex: "#FF00FF"))
            fill(ctx, rect: CGRect(x: 0, y: 0, width: 16, height: 16), color: .black)
            fill(ctx, rect: CGRect(x: 16, y: 16, width: 16, height: 16), color: .black)
        }
    }
}

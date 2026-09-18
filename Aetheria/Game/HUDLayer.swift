import SpriteKit

/// Screen-space HUD, attached as a child of the camera (z 50+).
final class HUDLayer: SKNode {
    private var hpBg: SKSpriteNode!
    private var mpBg: SKSpriteNode!
    private var xpBg: SKSpriteNode!
    private var hpFg: SKSpriteNode!
    private var mpFg: SKSpriteNode!
    private var xpFg: SKSpriteNode!
    private var levelLabel: SKLabelNode!
    private var goldLabel: SKLabelNode!
    private var bossBar: SKNode!
    private var bossFg: SKSpriteNode!
    private var bossName: SKLabelNode!
    private var bossHp: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var toastLabel: SKLabelNode!
    private var bannerTitle: SKLabelNode!
    private var bannerSub: SKLabelNode!
    private var lowHp: SKSpriteNode!
    private var lowHpOn = false
    private var critFlashNode: SKSpriteNode!
    private var toastQueue: [String] = []
    private var toastBusy = false

    private let barW: CGFloat = 300

    func setup() {
        zPosition = 50
        (hpBg, hpFg) = makeBar(color: SKColor(red: 0.95, green: 0.25, blue: 0.3, alpha: 1), height: 18)
        (mpBg, mpFg) = makeBar(color: SKColor(red: 0.25, green: 0.55, blue: 1, alpha: 1), height: 18)
        (xpBg, xpFg) = makeBar(color: SKColor(red: 0.7, green: 0.5, blue: 1, alpha: 1), height: 10)
        levelLabel = makeLabel(fontSize: 22, bold: true)
        levelLabel.horizontalAlignmentMode = .left
        addChild(levelLabel)
        goldLabel = makeLabel(fontSize: 22, bold: true)
        goldLabel.horizontalAlignmentMode = .right
        addChild(goldLabel)

        bossBar = SKNode()
        let bossBg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55), size: CGSize(width: 560, height: 22))
        bossFg = SKSpriteNode(color: SKColor(red: 0.9, green: 0.15, blue: 0.2, alpha: 1), size: CGSize(width: 556, height: 16))
        bossFg.anchorPoint = CGPoint(x: 0, y: 0.5)
        bossFg.position = CGPoint(x: -278, y: 0)
        bossName = makeLabel(fontSize: 22, bold: true)
        bossName.position = CGPoint(x: 0, y: 18)
        bossHp = makeLabel(fontSize: 16, bold: true)
        bossHp.position = CGPoint(x: 0, y: -24)
        bossBar.addChild(bossBg)
        bossBar.addChild(bossFg)
        bossBar.addChild(bossName)
        bossBar.addChild(bossHp)
        bossBar.isHidden = true
        addChild(bossBar)

        comboLabel = makeLabel(fontSize: 30, bold: true)
        comboLabel.fontColor = SKColor(red: 1, green: 0.8, blue: 0.25, alpha: 1)
        comboLabel.horizontalAlignmentMode = .right
        comboLabel.isHidden = true
        addChild(comboLabel)

        toastLabel = makeLabel(fontSize: 24, bold: true)
        toastLabel.alpha = 0
        addChild(toastLabel)

        bannerTitle = makeLabel(fontSize: 64, bold: true)
        bannerSub = makeLabel(fontSize: 26, bold: false)
        bannerTitle.alpha = 0
        bannerSub.alpha = 0
        addChild(bannerTitle)
        addChild(bannerSub)

        lowHp = SKSpriteNode(color: SKColor(red: 0.8, green: 0, blue: 0, alpha: 0), size: CGSize(width: 2000, height: 2000))
        lowHp.zPosition = -1
        addChild(lowHp)
        critFlashNode = SKSpriteNode(color: SKColor(white: 1, alpha: 0), size: CGSize(width: 2000, height: 2000))
        critFlashNode.zPosition = 10
        critFlashNode.alpha = 0
        addChild(critFlashNode)
    }

    private func makeBar(color: SKColor, height: CGFloat) -> (SKSpriteNode, SKSpriteNode) {
        let bg = SKSpriteNode(color: SKColor(white: 0, alpha: 0.55), size: CGSize(width: barW + 4, height: height + 4))
        let fg = SKSpriteNode(color: color, size: CGSize(width: barW, height: height))
        fg.anchorPoint = CGPoint(x: 0, y: 0.5)
        addChild(bg)
        addChild(fg)
        return (bg, fg)
    }

    private func makeLabel(fontSize: CGFloat, bold: Bool) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: bold ? "Helvetica-Bold" : "Helvetica")
        label.fontSize = fontSize
        label.fontColor = .white
        return label
    }

    /// Repositions everything for the current viewport size (camera space).
    /// `size` is the visible world rect (see GameScene.visibleSize) and
    /// `safeArea` is already converted to the same world units.
    func layout(size: CGSize, safeArea: UIEdgeInsets = .zero) {
        let hw = size.width / 2, hh = size.height / 2
        let leftX = -hw + 24 + safeArea.left
        let topY = hh - safeArea.top
        let rightX = hw - 30 - safeArea.right
        hpBg.position = CGPoint(x: leftX + barW / 2, y: topY - 30)
        hpFg.position = CGPoint(x: leftX, y: topY - 30)
        mpBg.position = CGPoint(x: leftX + barW / 2, y: topY - 58)
        mpFg.position = CGPoint(x: leftX, y: topY - 58)
        xpBg.position = CGPoint(x: leftX + barW / 2, y: topY - 80)
        xpFg.position = CGPoint(x: leftX, y: topY - 80)
        levelLabel.position = CGPoint(x: leftX, y: topY - 108)
        goldLabel.position = CGPoint(x: leftX + barW, y: topY - 108)
        bossBar.position = CGPoint(x: 0, y: topY - 72)
        comboLabel.position = CGPoint(x: rightX, y: topY - 190)
        toastLabel.position = CGPoint(x: 0, y: topY - 132)
        bannerTitle.position = CGPoint(x: 0, y: 40)
        bannerSub.position = CGPoint(x: 0, y: -12)
        lowHp.position = .zero
        lowHp.size = CGSize(width: size.width + 200, height: size.height + 200)
        critFlashNode.position = .zero
        critFlashNode.size = CGSize(width: size.width + 200, height: size.height + 200)
    }

    // MARK: - Updates

    private var lastLevelShown = -1

    func setBars(hp: Double, maxHp: Double, mana: Double, maxMana: Double, xp: Int, xpNext: Int, level: Int) {
        hpFg.xScale = max(0.001, CGFloat(hp / max(1, maxHp)))
        mpFg.xScale = max(0.001, CGFloat(mana / max(1, maxMana)))
        xpFg.xScale = max(0.001, CGFloat(Double(xp) / Double(max(1, xpNext))))
        // Setting text re-renders the label texture: only touch it on change.
        if level != lastLevelShown {
            lastLevelShown = level
            levelLabel.text = "\(L.t("common.level")) \(level)"
        }
    }

    func setGold(_ gold: Int) {
        goldLabel.text = "● \(gold)"
        goldLabel.fontColor = SKColor(red: 1, green: 0.85, blue: 0.35, alpha: 1)
    }

    func showBoss(name: String) {
        bossName.text = name
        bossFg.xScale = 1
        bossBar.isHidden = false
    }

    func setBossHp(cur: Double, maxHp: Double) {
        bossFg.xScale = max(0.001, CGFloat(cur / max(1, maxHp)))
        bossHp.text = "\(max(0, Int(cur))) / \(Int(maxHp))"
    }

    func hideBoss() {
        bossBar.isHidden = true
    }

    func showCombo(_ count: Int) {
        comboLabel.isHidden = false
        var text = "\(count) \(L.t("hud.combo"))!"
        let rank: String? = count >= 30 ? L.t("combo.r30")
            : count >= 20 ? L.t("combo.r20")
            : count >= 10 ? L.t("combo.r10")
            : count >= 5 ? L.t("combo.r5") : nil
        if let rank { text += " · \(rank)" }
        comboLabel.text = text
        comboLabel.setScale(1.25)
        comboLabel.run(SKAction.scale(to: 1.0, duration: 0.15))
    }

    func hideCombo() {
        comboLabel.isHidden = true
    }

    func toast(_ text: String) {
        toastQueue.append(text)
        if !toastBusy { nextToast() }
    }

    private func nextToast() {
        guard !toastQueue.isEmpty else {
            toastBusy = false
            return
        }
        toastBusy = true
        toastLabel.text = toastQueue.removeFirst()
        toastLabel.alpha = 0
        toastLabel.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 1.8),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.run { [weak self] in self?.nextToast() },
        ]))
    }

    func banner(title: String, sub: String) {
        bannerTitle.text = title
        bannerSub.text = sub
        for label in [bannerTitle, bannerSub] {
            label?.alpha = 0
            label?.run(SKAction.sequence([
                SKAction.fadeIn(withDuration: 0.5),
                SKAction.wait(forDuration: 2.2),
                SKAction.fadeOut(withDuration: 0.6),
            ]))
        }
    }

    /// White screen flash for crits and Second Wind revives.
    func critFlash() {
        critFlashNode.removeAction(forKey: "flash")
        critFlashNode.alpha = 0.28
        critFlashNode.run(SKAction.fadeOut(withDuration: 0.18), withKey: "flash")
    }

    func setLowHp(_ on: Bool) {
        // Called every frame: only touch actions on state change.
        guard on != lowHpOn else { return }
        lowHpOn = on
        lowHp.removeAction(forKey: "pulse")
        if on {
            lowHp.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.22, duration: 0.6),
                SKAction.fadeAlpha(to: 0.05, duration: 0.6),
            ])), withKey: "pulse")
        } else {
            lowHp.alpha = 0
        }
    }
}

// MARK: - Floating damage numbers (world space)

final class DamageLayer: SKNode {
    private var pool: [SKLabelNode] = []
    private var index = 0

    func setup() {
        zPosition = 20
        for _ in 0..<28 {
            let label = SKLabelNode(fontNamed: "Helvetica-Bold")
            label.fontSize = 22
            label.alpha = 0
            addChild(label)
            pool.append(label)
        }
    }

    func spawn(text: String, at pos: CGPoint, color: SKColor, big: Bool) {
        guard AppSettings.shared.damageNumbers else { return }
        let label = pool[index]
        index = (index + 1) % pool.count
        label.removeAllActions()
        label.text = text
        label.fontColor = color
        label.fontSize = big ? 32 : 21
        label.position = pos + CGPoint(x: CGFloat.random(in: -10...10), y: 10)
        label.alpha = 1
        label.setScale(big ? 1.3 : 1.0)
        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -24...24), y: 64, duration: 0.7),
                SKAction.scale(to: big ? 1.0 : 0.85, duration: 0.7),
            ]),
            SKAction.fadeOut(withDuration: 0.2),
        ]))
    }
}

import Foundation

/// Pure combat math: XP curves, derived stats, damage rolls.
enum CombatFormulas {
    // MARK: - XP

    static func xpForLevel(_ level: Int) -> Int {
        Int(60.0 * pow(Double(level), 1.55)) + 40
    }

    static func xpReward(base: Int, level: Int, bonus: Double) -> Int {
        max(1, Int(Double(base) * (1.0 + bonus)))
    }

    // MARK: - Derived stats

    static func derivedStats(for session: GameSession) -> DerivedStats {
        let db = ContentDatabase.shared
        let hero = session.hero
        let total = Stats(
            strength: hero.stats.strength + session.baseStats.strength,
            agility: hero.stats.agility + session.baseStats.agility,
            vitality: hero.stats.vitality + session.baseStats.vitality,
            intelligence: hero.stats.intelligence + session.baseStats.intelligence
        )

        var maxHP = 70.0 + Double(total.vitality) * 14.0
        var maxMana = 30.0 + Double(total.intelligence) * 9.0
        var attack = 6.0 + Double(total.strength) * 2.6 + Double(session.level - 1) * 1.5
        var magic = 5.0 + Double(total.intelligence) * 2.8 + Double(session.level - 1) * 1.5
        var defense = Double(total.agility) * 0.5 + Double(total.vitality) * 0.4
        var crit = 0.05 + Double(total.agility) * 0.008
        var moveSpeed = 320.0 + Double(total.agility) * 4.0
        var lifesteal = 0.0
        var xpBonus = 0.0
        var goldBonus = 0.0
        var dashCooldown = 1.6
        var spellCost = 1.0
        var attackPct = 0.0, magicPct = 0.0, hpPct = 0.0, speedPct = 0.0
        var canDoubleJump = false, canDash = true, canAirAttack = false
        var secondWind = false

        // Class passives
        switch hero.id {
        case "ranger": crit += 0.05; moveSpeed += 25
        case "mage": maxMana += 20; magic += 4
        case "knight": maxHP += 25; defense += 2
        default: break
        }

        // Equipment
        for slot in [session.equipment.weapon, session.equipment.armor, session.equipment.trinket] {
            guard let slot, let def = db.items[slot.itemId] else { continue }
            attack += def.stats["attack"] ?? 0
            magic += def.stats["magic"] ?? 0
            defense += def.stats["defense"] ?? 0
            maxHP += def.stats["maxHealth"] ?? 0
            maxMana += def.stats["maxMana"] ?? 0
            crit += def.stats["crit"] ?? 0
            moveSpeed += def.stats["moveSpeed"] ?? 0
            lifesteal += def.stats["lifesteal"] ?? 0
        }

        // Skills
        for (skillId, rank) in session.skills where rank > 0 {
            guard let def = db.skills[skillId] else { continue }
            let r = Double(rank)
            let m = def.modifiers
            attackPct += (m["attackPct"] ?? 0) * r
            attack += (m["attackFlat"] ?? 0) * r
            magicPct += (m["magicPct"] ?? 0) * r
            hpPct += (m["maxHealthPct"] ?? 0) * r
            maxHP += (m["maxHealthFlat"] ?? 0) * r
            maxMana += (m["maxManaFlat"] ?? 0) * r
            defense += (m["defenseFlat"] ?? 0) * r
            crit += (m["critChance"] ?? 0) * r
            speedPct += (m["moveSpeedPct"] ?? 0) * r
            lifesteal += (m["lifesteal"] ?? 0) * r
            xpBonus += (m["xpPct"] ?? 0) * r
            goldBonus += (m["goldPct"] ?? 0) * r
            dashCooldown += (m["dashCooldownFlat"] ?? 0) * r
            spellCost += (m["spellCostPct"] ?? 0) * r
            switch def.unlock {
            case "doubleJump": canDoubleJump = true
            case "dash": canDash = true
            case "airAttack": canAirAttack = true
            case "secondWind": secondWind = true
            default: break
            }
        }

        attack *= 1.0 + attackPct
        magic *= 1.0 + magicPct
        maxHP *= 1.0 + hpPct
        moveSpeed *= 1.0 + speedPct

        return DerivedStats(
            maxHP: max(20, maxHP),
            maxMana: max(10, maxMana),
            attack: max(1, attack),
            magicPower: max(1, magic),
            defense: max(0, defense),
            critChance: min(0.75, crit),
            critDamage: 1.8,
            moveSpeed: min(520, moveSpeed),
            lifesteal: min(0.35, lifesteal),
            xpBonus: xpBonus,
            goldBonus: goldBonus,
            dashCooldown: max(0.5, dashCooldown),
            canDoubleJump: canDoubleJump,
            canDash: canDash,
            canAirAttack: canAirAttack,
            secondWind: secondWind,
            spellCostMultiplier: max(0.4, spellCost)
        )
    }

    // MARK: - Damage

    /// Melee swing damage with combo scaling and crit roll.
    static func meleeDamage(derived: DerivedStats, comboIndex: Int) -> (damage: Double, crit: Bool) {
        let comboMult = [1.0, 1.05, 1.5][min(max(comboIndex, 0), 2)]
        let variance = Double.random(in: 0.9...1.1)
        let crit = Double.random(in: 0...1) < derived.critChance
        var dmg = derived.attack * comboMult * variance
        if crit { dmg *= derived.critDamage }
        return (dmg, crit)
    }

    static func spellDamage(derived: DerivedStats) -> (damage: Double, crit: Bool) {
        let variance = Double.random(in: 0.9...1.1)
        let crit = Double.random(in: 0...1) < derived.critChance * 0.7
        var dmg = derived.magicPower * 1.6 * variance
        if crit { dmg *= derived.critDamage }
        return (dmg, crit)
    }

    /// Damage after armor. Armor has diminishing returns.
    static func mitigated(raw: Double, defense: Double) -> Double {
        let reduction = defense / (defense + 60.0)
        return max(1, raw * (1.0 - min(0.75, reduction)))
    }

    static func enemyContactDamage(base: Double) -> Double {
        base * AppSettings.shared.difficulty.enemyDamage
    }
}

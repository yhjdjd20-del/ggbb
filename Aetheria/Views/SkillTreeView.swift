import SwiftUI

/// Growth screen: skill trees (3 branches) + attribute points.
struct SkillTreeView: View {
    @ObservedObject var vm: GameViewModel

    @State private var tab = 0
    @State private var branch: SkillBranch = .might

    private let branchColors: [SkillBranch: Color] = [
        .might: Color(hex: "#FF7B2E"),
        .shadow: Color(hex: "#3FD97C"),
        .arcane: Color(hex: "#B45CFF"),
    ]

    var body: some View {
        ZStack {
            FullscreenDim()
            Panel(title: L.t("skill.title")) {
                VStack(spacing: 10) {
                    Picker("", selection: $tab) {
                        Text(L.t("skill.tabs.skills")).tag(0)
                        Text(L.t("skill.tabs.attrs")).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 320)
                    if tab == 0 {
                        skillsTab
                    } else {
                        attributesTab
                    }
                    SmallButton(label: L.t("common.close")) {
                        vm.showSkills = false
                    }
                }
                .frame(width: 640)
            }
        }
    }

    // MARK: - Skills

    private var branchSkills: [SkillDefinition] {
        ContentDatabase.shared.skills.values
            .filter { $0.branch == branch }
            .sorted { $0.tier < $1.tier }
    }

    private var skillsTab: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(L.t("skill.points")): \(vm.session.skillPoints)")
                    .font(.headline)
                    .foregroundColor(.gold)
                Spacer()
                Picker("", selection: $branch) {
                    ForEach(SkillBranch.allCases, id: \.self) { branch in
                        Text(branch.title).tag(branch)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(branchSkills) { skill in
                        skillRow(skill)
                    }
                }
            }
            .frame(height: 300)
            powerSummary
        }
    }

    private func skillRow(_ skill: SkillDefinition) -> some View {
        let rank = vm.session.skills[skill.id] ?? 0
        let maxed = rank >= skill.maxRank
        let canLearn = vm.canLearn(skill)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(skill.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text("T\(skill.tier + 1)")
                        .font(.caption2.bold())
                        .foregroundColor(.dimText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(6)
                }
                Text(skill.displayDescription)
                    .font(.caption)
                    .foregroundColor(.dimText)
                    .lineLimit(2)
                if !skill.requires.isEmpty {
                    Text("\(L.t("skill.req")): \(reqNames(skill))")
                        .font(.caption2)
                        .foregroundColor(.dimText.opacity(0.8))
                }
            }
            Spacer()
            // Rank pips.
            HStack(spacing: 3) {
                ForEach(0..<skill.maxRank, id: \.self) { i in
                    Circle()
                        .fill(i < rank ? branchColors[branch]! : Color(hex: "#2A3350"))
                        .frame(width: 10, height: 10)
                }
            }
            SmallButton(label: maxed ? L.t("common.maxed") : (rank == 0 ? L.t("skill.learn") : L.t("skill.improve")),
                        enabled: canLearn) {
                vm.learnSkill(skill)
            }
        }
        .padding(8)
        .background(Color(hex: "#1E2438"))
        .cornerRadius(10)
    }

    private var powerSummary: some View {
        let derived = vm.derivedStats()
        return HStack(spacing: 16) {
            Text(L.t("skill.summary") + ":")
                .font(.caption)
                .foregroundColor(.dimText)
            summaryChip("⚔ \(Int(derived.attack))")
            summaryChip("✦ \(Int(derived.magicPower))")
            summaryChip("🛡 \(Int(derived.defense))")
            summaryChip("❤ \(Int(derived.maxHP))")
            if derived.canDoubleJump { summaryChip("×2 ⤴") }
        }
    }

    private func summaryChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "#2A3350"))
            .cornerRadius(8)
    }

    private func reqNames(_ skill: SkillDefinition) -> String {
        skill.requires.map { req in
            let name = ContentDatabase.shared.skills[req.skill]?.displayName ?? req.skill
            return "\(name) \(req.rank)"
        }.joined(separator: ", ")
    }

    // MARK: - Attributes

    private var attributesTab: some View {
        VStack(spacing: 10) {
            Text("\(L.t("skill.attrPoints")): \(vm.session.statPoints)")
                .font(.headline)
                .foregroundColor(.gold)
            SmallButton(label: L.t("skill.respec")) {
                vm.respecAttributes()
            }
            attrRow(L.t("char.str"), L.t("skill.str.d"), \Stats.strength)
            attrRow(L.t("char.agi"), L.t("skill.agi.d"), \Stats.agility)
            attrRow(L.t("char.vit"), L.t("skill.vit.d"), \Stats.vitality)
            attrRow(L.t("char.int"), L.t("skill.int.d"), \Stats.intelligence)
            powerSummary
        }
    }

    private func attrRow(_ label: String, _ desc: String, _ keyPath: WritableKeyPath<Stats, Int>) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(label): \(vm.session.hero.stats[keyPath: keyPath] + vm.session.baseStats[keyPath: keyPath])")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.dimText)
            }
            Spacer()
            SmallButton(label: "+1", enabled: vm.session.statPoints > 0) {
                vm.addStatPoint(keyPath)
            }
        }
        .padding(8)
        .background(Color(hex: "#1E2438"))
        .cornerRadius(10)
    }
}

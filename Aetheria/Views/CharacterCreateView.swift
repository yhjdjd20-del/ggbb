import SwiftUI

/// Hero creation: name + class (Knight / Ranger / Mage).
struct CharacterCreateView: View {
    @ObservedObject var vm: GameViewModel
    var slot: Int
    var onBack: () -> Void

    @State private var heroName = ""
    @State private var classId = "knight"

    private var hero: HeroClass { HeroClass.withId(classId) }

    var body: some View {
        HStack {
            Spacer()
            Panel(title: L.t("char.title")) {
                VStack(spacing: 12) {
                    // Name row.
                    HStack {
                        Text(L.t("char.name") + ":")
                            .foregroundColor(.dimText)
                        TextField(L.t("char.namePh"), text: $heroName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                        SmallButton(label: "🎲 \(L.t("char.random"))") {
                            heroName = vm.randomHeroName()
                        }
                    }
                    // Class cards.
                    HStack(spacing: 10) {
                        ForEach(HeroClass.all) { cls in
                            classCard(cls)
                        }
                    }
                    // Details.
                    if let weapon = ContentDatabase.shared.items[hero.weaponId] {
                        StatRow(label: L.t("char.weapon"), value: weapon.displayName, valueColor: .gold)
                    }
                    if let skillId = hero.bonusSkill, let skill = ContentDatabase.shared.skills[skillId] {
                        StatRow(label: L.t("char.bonus"), value: skill.displayName, valueColor: Color(hex: "#B45CFF"))
                    }
                    // Actions.
                    HStack(spacing: 10) {
                        MenuButton(label: L.t("common.back"), icon: "chevron.left", accent: Color(hex: "#9AA3B2")) {
                            onBack()
                        }
                        MenuButton(label: L.t("char.start"), icon: "play.fill", accent: Color(hex: "#3FD97C")) {
                            vm.newGame(heroName: heroName.trimmingCharacters(in: .whitespaces), classId: classId, slot: slot)
                        }
                    }
                }
                .frame(width: 450)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            if heroName.isEmpty { heroName = vm.randomHeroName() }
        }
    }

    private func classCard(_ cls: HeroClass) -> some View {
        let selected = cls.id == classId
        return Button(action: {
            SoundManager.shared.play("select")
            classId = cls.id
        }) {
            VStack(spacing: 6) {
                Image(uiImage: TextureFactory.uiImage("player_\(cls.id)_attack_1"))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: 68)
                Text(cls.displayName)
                    .font(.headline)
                    .foregroundColor(selected ? .white : .dimText)
                Text(cls.displayDescription)
                    .font(.caption)
                    .foregroundColor(.dimText)
                    .multilineTextAlignment(.center)
                    .frame(height: 46)
                HStack(spacing: 8) {
                    attrChip(L.t("char.str"), cls.stats.strength)
                    attrChip(L.t("char.agi"), cls.stats.agility)
                    attrChip(L.t("char.vit"), cls.stats.vitality)
                    attrChip(L.t("char.int"), cls.stats.intelligence)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(selected ? Color(hex: cls.colorHex).opacity(0.18) : Color(hex: "#1E2438"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color(hex: cls.colorHex) : Color.panelBorder, lineWidth: selected ? 2.5 : 1)
            )
        }
    }

    private func attrChip(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.dimText)
            Text("\(value)")
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}

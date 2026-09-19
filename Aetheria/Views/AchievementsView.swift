import SwiftUI

/// Cross-adventure achievement collection.
struct AchievementsView: View {
    var onBack: () -> Void

    private var unlocked: Set<String> { AchievementStore.unlocked }

    var body: some View {
        HStack {
            Spacer()
            Panel(title: "\(L.t("ach.title")) (\(unlocked.count)/\(AchievementManager.all.count))") {
                VStack(spacing: 12) {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(AchievementManager.all) { def in
                                achievementRow(def)
                            }
                        }
                    }
                    .frame(height: 310)
                    MenuButton(label: L.t("common.back"), icon: "chevron.left") {
                        onBack()
                    }
                }
                .frame(width: 500)
            }
            Spacer()
        }
        .padding()
    }

    private func achievementRow(_ def: AchievementDefinition) -> some View {
        let got = unlocked.contains(def.id)
        return HStack(spacing: 12) {
            ItemIconView(icon: def.icon, rarity: got ? .legendary : nil, size: 36)
                .opacity(got ? 1 : 0.4)
                .grayscale(got ? 0 : 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(def.title)
                    .font(.subheadline.bold())
                    .foregroundColor(got ? .white : .dimText)
                Text(got ? def.details : L.t("ach.locked"))
                    .font(.caption)
                    .foregroundColor(.dimText)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(8)
        .background(Color(hex: "#1E2438"))
        .cornerRadius(10)
    }
}

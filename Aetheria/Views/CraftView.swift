import SwiftUI

/// Forge: brew consumables from monster materials.
struct CraftView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            FullscreenDim()
            Panel(title: "\(L.t("craft.title"))  ● \(vm.session.gold)") {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(GameViewModel.recipes.enumerated()), id: \.offset) { _, recipe in
                            recipeRow(recipe)
                        }
                    }
                }
                .frame(width: 420, height: 300)
                SmallButton(label: L.t("common.close")) {
                    vm.showCraft = false
                }
            }
        }
    }

    private func recipeRow(_ recipe: GameViewModel.CraftRecipe) -> some View {
        let db = ContentDatabase.shared
        let def = db.items[recipe.result]
        return HStack(spacing: 8) {
            ItemIconView(icon: def?.icon ?? "potion", rarity: def?.rarity, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text((def?.displayName ?? recipe.result) + (recipe.quantity > 1 ? " ×\(recipe.quantity)" : ""))
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Text(costLine(recipe))
                    .font(.caption)
                    .foregroundColor(vm.canCraft(recipe) ? Color(hex: "#3FD97C") : .dimText)
            }
            Spacer()
            SmallButton(label: L.t("craft.make"), enabled: vm.canCraft(recipe)) {
                vm.craftItem(recipe)
            }
        }
        .padding(8)
        .background(Color(hex: "#1E2438"))
        .cornerRadius(10)
    }

    private func costLine(_ recipe: GameViewModel.CraftRecipe) -> String {
        let db = ContentDatabase.shared
        var parts = recipe.materials.map { mat -> String in
            let have = vm.session.inventoryCount(itemId: mat.itemId)
            let name = db.items[mat.itemId]?.displayName ?? mat.itemId
            return "\(name) \(have)/\(mat.count)"
        }
        parts.append("● \(recipe.gold)")
        return parts.joined(separator: "   ")
    }
}

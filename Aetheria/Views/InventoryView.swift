import SwiftUI

/// Equipment + backpack with filters, item details and actions.
struct InventoryView: View {
    @ObservedObject var vm: GameViewModel

    @State private var filter: String = "all"
    @State private var selectedId: String?

    private var filteredItems: [InventoryItem] {
        let db = ContentDatabase.shared
        return vm.session.inventory
            .filter { item in
                guard let def = db.items[item.itemId] else { return false }
                if filter == "all" { return true }
                if filter == "gear" { return def.type == .weapon || def.type == .armor || def.type == .trinket }
                return def.type.rawValue == filter
            }
            .sorted {
                let a = db.items[$0.itemId]!, b = db.items[$1.itemId]!
                if a.rarity.sortOrder != b.rarity.sortOrder { return a.rarity.sortOrder > b.rarity.sortOrder }
                return a.displayName < b.displayName
            }
    }

    private var selectedItem: InventoryItem? {
        vm.session.inventory.first(where: { $0.id == selectedId })
    }

    var body: some View {
        ZStack {
            FullscreenDim()
            Panel(title: "\(L.t("inv.title"))  ● \(vm.session.gold)") {
                HStack(alignment: .top, spacing: 16) {
                    // Left: equipment + filters + grid.
                    VStack(alignment: .leading, spacing: 10) {
                        equipmentRow
                        filterRow
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(56), spacing: 8), count: 6), spacing: 8) {
                                ForEach(filteredItems) { item in
                                    itemCell(item)
                                }
                            }
                            .padding(2)
                        }
                        .frame(width: 400, height: 250)
                    }
                    // Right: details.
                    detailPanel
                        .frame(width: 280)
                }
                SmallButton(label: L.t("common.close")) {
                    vm.showInventory = false
                }
            }
        }
    }

    // MARK: - Equipment

    private var equipmentRow: some View {
        HStack(spacing: 12) {
            Text(L.t("inv.equipment") + ":")
                .font(.subheadline)
                .foregroundColor(.dimText)
            equipSlot(vm.session.equipment.weapon, label: L.t("inv.weapon"), slot: "weapon")
            equipSlot(vm.session.equipment.armor, label: L.t("inv.armor"), slot: "armor")
            equipSlot(vm.session.equipment.trinket, label: L.t("inv.trinket"), slot: "trinket")
        }
    }

    private func equipSlot(_ item: InventoryItem?, label: String, slot: String) -> some View {
        VStack(spacing: 2) {
            if let item, let def = ContentDatabase.shared.items[item.itemId] {
                Button(action: { vm.unequip(slot: slot) }) {
                    ItemIconView(icon: def.icon, rarity: def.rarity, size: 46)
                }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.panelBorder, lineWidth: 1)
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: "questionmark").foregroundColor(.dimText))
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.dimText)
        }
    }

    // MARK: - Grid

    private var filterRow: some View {
        HStack(spacing: 6) {
            ForEach([("all", L.t("inv.all")), ("gear", "⚔"), ("consumable", L.t("inv.consumable")),
                     ("material", L.t("inv.material")), ("keyItem", L.t("inv.keyItem"))], id: \.0) { key, label in
                Button(action: { filter = key }) {
                    Text(label)
                        .font(.caption.bold())
                        .foregroundColor(filter == key ? .white : .dimText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(filter == key ? Color(hex: "#4DA3FF").opacity(0.4) : Color(hex: "#1E2438"))
                        .cornerRadius(8)
                }
            }
        }
    }

    private func itemCell(_ item: InventoryItem) -> some View {
        guard let def = ContentDatabase.shared.items[item.itemId] else {
            return AnyView(EmptyView())
        }
        let selected = item.id == selectedId
        return AnyView(
            Button(action: {
                SoundManager.shared.play("select")
                selectedId = item.id
            }) {
                ZStack(alignment: .bottomTrailing) {
                    ItemIconView(icon: def.icon, rarity: def.rarity, size: 52)
                    if item.quantity > 1 {
                        Text("\(item.quantity)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.75))
                            .clipShape(Circle())
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Color.white : Color.clear, lineWidth: 2))
            }
        )
    }

    // MARK: - Details

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let item = selectedItem, let def = ContentDatabase.shared.items[item.itemId] {
                HStack {
                    ItemIconView(icon: def.icon, rarity: def.rarity, size: 56)
                    VStack(alignment: .leading) {
                        Text(def.displayName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(def.rarity.title)
                            .font(.caption.bold())
                            .foregroundColor(rarityColor(def.rarity))
                    }
                }
                Text(def.displayDescription)
                    .font(.caption)
                    .foregroundColor(.dimText)
                    .frame(minHeight: 40, alignment: .top)
                ForEach(statLines(def), id: \.self) { line in
                    Text(line)
                        .font(.caption)
                        .foregroundColor(Color(hex: "#7DF9FF"))
                }
                Text("\(L.t("inv.sell")): \(def.price / 2) \(L.t("common.gold"))")
                    .font(.caption)
                    .foregroundColor(.dimText)
                HStack(spacing: 8) {
                    if def.usable {
                        SmallButton(label: L.t("inv.use")) {
                            if !vm.useItem(item) { SoundManager.shared.play("error") }
                        }
                    }
                    if def.type == .weapon || def.type == .armor || def.type == .trinket {
                        SmallButton(label: L.t("inv.equip")) {
                            vm.equipItem(item)
                            selectedId = nil
                        }
                    }
                    if def.type != .keyItem {
                        SmallButton(label: L.t("inv.drop")) {
                            vm.dropItem(item)
                            selectedId = nil
                        }
                    }
                }
            } else {
                Text(L.t("common.empty"))
                    .foregroundColor(.dimText.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(12)
        .background(Color(hex: "#1E2438"))
        .cornerRadius(12)
        .frame(minHeight: 300)
    }

    private func statLines(_ def: ItemDefinition) -> [String] {
        var lines: [String] = []
        let names: [String: String] = [
            "attack": L.t("common.damage"), "magic": L.t("common.damage") + " ✦",
            "defense": L.t("common.defense"), "maxHealth": "+\(L.t("inv.hp"))",
            "maxMana": "+\(L.t("inv.mp"))", "crit": "Crit", "moveSpeed": "Speed",
            "heal": L.t("inv.heal"), "mana": L.t("inv.heal") + " MP",
            "lifesteal": "Lifesteal", "damage": L.t("common.damage"),
        ]
        for (key, value) in def.stats.sorted(by: { $0.key < $1.key }) {
            let label = names[key] ?? key
            let formatted: String
            if key == "crit" || key == "lifesteal" {
                formatted = String(format: "%+.0f%%", value * 100)
            } else {
                formatted = String(format: "%+.0f", value)
            }
            lines.append("\(label): \(formatted)")
        }
        return lines
    }
}

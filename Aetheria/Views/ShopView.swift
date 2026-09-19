import SwiftUI

/// Merchant shop: buy consumables and gear for gold.
struct ShopView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            FullscreenDim()
            Panel(title: "\(L.t("shop.title"))  ● \(vm.session.gold)") {
                VStack(spacing: 8) {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(vm.shopItems) { item in
                                shopRow(item)
                            }
                        }
                    }
                    .frame(width: 460, height: 280)
                    SmallButton(label: L.t("dlg.leave")) {
                        vm.closeShop()
                    }
                }
            }
        }
    }

    private func shopRow(_ item: ShopItem) -> some View {
        guard let def = ContentDatabase.shared.items[item.itemId] else {
            return AnyView(EmptyView())
        }
        let affordable = vm.session.gold >= item.price
        let soldOut = item.stock == 0
        return AnyView(
            HStack(spacing: 10) {
                ItemIconView(icon: def.icon, rarity: def.rarity, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(def.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Text(def.displayDescription)
                        .font(.caption)
                        .foregroundColor(.dimText)
                        .lineLimit(1)
                }
                Spacer()
                if item.stock > 0 {
                    Text("×\(item.stock)")
                        .font(.caption.bold())
                        .foregroundColor(.dimText)
                }
                Text("● \(item.price)")
                    .font(.subheadline.bold())
                    .foregroundColor(affordable ? .gold : .red.opacity(0.8))
                    .frame(width: 66, alignment: .trailing)
                SmallButton(label: soldOut ? "—" : L.t("shop.buy"), enabled: affordable && !soldOut) {
                    vm.buyItem(item)
                }
            }
            .padding(6)
            .background(Color(hex: "#1E2438"))
            .cornerRadius(8)
        )
    }
}

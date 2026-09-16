import SwiftUI

/// Three save slots: continue an adventure, start a new one, or delete.
struct SaveSlotView: View {
    @ObservedObject var vm: GameViewModel
    var onBack: () -> Void
    var onCreate: (Int) -> Void

    @State private var sessions: [GameSession?] = [nil, nil, nil]
    @State private var deleteSlot: Int?

    var body: some View {
        HStack {
            Spacer()
            Panel(title: L.t("slots.title")) {
                VStack(spacing: 12) {
                    ForEach(0..<SaveManager.slotCount, id: \.self) { slot in
                        slotRow(slot)
                    }
                    MenuButton(label: L.t("common.back"), icon: "chevron.left") {
                        onBack()
                    }
                }
                .frame(width: 440)
            }
            Spacer()
        }
        .padding()
        .alert(Text(L.t("slots.deleteTitle")), isPresented: Binding(
            get: { deleteSlot != nil },
            set: { if !$0 { deleteSlot = nil } }
        )) {
            Button(L.t("common.cancel"), role: .cancel) { deleteSlot = nil }
            Button(L.t("slots.delete"), role: .destructive) {
                if let slot = deleteSlot {
                    SaveManager.delete(slot: slot)
                    reload()
                    deleteSlot = nil
                }
            }
        } message: {
            Text(L.t("slots.deleteMsg"))
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        sessions = (0..<SaveManager.slotCount).map { SaveManager.load(slot: $0) }
    }

    @ViewBuilder
    private func slotRow(_ slot: Int) -> some View {
        if let session = sessions[slot] {
            HStack(spacing: 14) {
                Image(uiImage: TextureFactory.uiImage("player_\(session.heroClass)_idle_0"))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 44, height: 60)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.heroName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(session.hero.displayName) · \(L.t("common.level")) \(session.level)")
                        .font(.subheadline)
                        .foregroundColor(.dimText)
                    Text("\(formatPlayTime(session.stats.playTime)) · \(formatDate(session.savedAt))")
                        .font(.caption)
                        .foregroundColor(.dimText.opacity(0.8))
                }
                Spacer()
                Button(action: { deleteSlot = slot }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                        .padding(8)
                }
                SmallButton(label: "▶") {
                    vm.continueGame(slot: slot)
                }
            }
            .padding(10)
            .background(Color(hex: "#1E2438"))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.panelBorder, lineWidth: 1))
        } else {
            Button(action: { onCreate(slot) }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text(L.t("slots.empty"))
                    Spacer()
                    Text(L.t("menu.new"))
                        .font(.caption)
                        .foregroundColor(.dimText)
                }
                .foregroundColor(.white)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#1E2438").opacity(0.6))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.panelBorder.opacity(0.6), lineWidth: 1))
            }
        }
    }
}

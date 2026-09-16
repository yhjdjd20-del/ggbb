import SwiftUI

/// Quest journal: main / side / completed with objectives and tracking.
struct QuestLogView: View {
    @ObservedObject var vm: GameViewModel
    @State private var tab = 0

    private var quests: [QuestDefinition] {
        let db = ContentDatabase.shared
        let all = db.quests.values.sorted { $0.id < $1.id }
        switch tab {
        case 0:
            return all.filter { $0.kind == .main && vm.questState($0.id) != .turnedIn && vm.session.quests[$0.id] != nil }
        case 1:
            return all.filter { $0.kind == .side && vm.questState($0.id) != .turnedIn && vm.session.quests[$0.id] != nil }
        default:
            return all.filter { vm.questState($0.id) == .turnedIn }
        }
    }

    var body: some View {
        ZStack {
            FullscreenDim()
            Panel(title: L.t("quest.title")) {
                VStack(spacing: 10) {
                    Picker("", selection: $tab) {
                        Text(L.t("quest.main")).tag(0)
                        Text(L.t("quest.side")).tag(1)
                        Text(L.t("quest.done")).tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 380)
                    ScrollView {
                        VStack(spacing: 8) {
                            if quests.isEmpty {
                                Text(L.t("common.empty"))
                                    .foregroundColor(.dimText.opacity(0.6))
                                    .padding()
                            }
                            ForEach(quests) { quest in
                                questRow(quest)
                            }
                        }
                    }
                    .frame(width: 620, height: 330)
                    SmallButton(label: L.t("common.close")) {
                        vm.showQuests = false
                    }
                }
            }
        }
    }

    private func questRow(_ quest: QuestDefinition) -> some View {
        let progress = vm.session.quests[quest.id]
        let tracked = vm.session.trackedQuest == quest.id
        let ready = progress?.state == .readyToTurnIn
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(quest.displayTitle)
                    .font(.headline)
                    .foregroundColor(ready ? .gold : .white)
                if ready {
                    Text(L.t("quest.ready"))
                        .font(.caption2.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.gold)
                        .cornerRadius(8)
                }
                Spacer()
                if progress?.state == .active || ready {
                    SmallButton(label: tracked ? "✓ \(L.t("quest.tracked"))" : L.t("quest.track")) {
                        vm.trackQuest(quest.id)
                    }
                }
            }
            Text(quest.displayDescription)
                .font(.caption)
                .foregroundColor(.dimText)
            if let progress {
                ForEach(Array(zip(quest.objectives, progress.counts).enumerated()), id: \.offset) { _, pair in
                    let (obj, count) = pair
                    HStack(spacing: 6) {
                        Image(systemName: count >= obj.count ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(count >= obj.count ? Color(hex: "#3FD97C") : .dimText)
                            .font(.caption)
                        Text("\(localized(obj.text, obj.textRu))  \(count)/\(obj.count)")
                            .font(.caption)
                            .foregroundColor(count >= obj.count ? .dimText : .white)
                    }
                }
            }
            if let turnIn = quest.turnIn, ready {
                Text("\(L.t("quest.turnIn")): \(turnIn)")
                    .font(.caption)
                    .foregroundColor(.gold)
            }
        }
        .padding(10)
        .background(Color(hex: "#1E2438"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(tracked ? Color.gold.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
    }
}

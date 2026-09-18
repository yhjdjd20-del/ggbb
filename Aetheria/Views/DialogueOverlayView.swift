import SwiftUI

/// Bottom dialogue panel with speaker portrait and choices.
struct DialogueOverlayView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        ZStack {
            FullscreenDim()
            VStack {
                Spacer()
                if let node = vm.currentDialogueNode(), let dlg = vm.activeDialogue {
                    HStack(alignment: .top, spacing: 16) {
                        Image(uiImage: TextureFactory.uiImage("npc_\(dlg.npcId)"))
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 90, height: 130)
                            .background(Color(hex: "#1E2438"))
                            .cornerRadius(12)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(node.displaySpeaker)
                                .font(.headline)
                                .foregroundColor(.gold)
                            ScrollView {
                                Text(node.displayText)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 70)
                            choiceList
                        }
                    }
                    .padding(18)
                    .frame(width: 700)
                    .background(Color.panelBg)
                    .cornerRadius(18)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.panelBorder, lineWidth: 2))
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private var choiceList: some View {
        VStack(spacing: 6) {
            if vm.visibleChoices().isEmpty {
                // All choices gated by unmet requirements: never soft-lock.
                leaveButton
            } else {
                ForEach(Array(vm.visibleChoices().enumerated()), id: \.offset) { _, choice in
                    choiceButton(choice)
                }
            }
        }
    }

    private var leaveButton: some View {
        Button(action: { vm.closeDialogue() }) {
            HStack {
                Text(L.t("dlg.leave"))
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#2A3350"))
            .cornerRadius(10)
        }
    }

    private func choiceButton(_ choice: DialogueChoice) -> some View {
        let special = choice.turnInQuest != nil || choice.givesQuest != nil
        return Button(action: { vm.chooseDialogue(choice) }) {
            HStack {
                if choice.openShop == true {
                    Image(systemName: "bag.fill")
                } else if choice.turnInQuest != nil {
                    Image(systemName: "checkmark.circle.fill")
                } else if choice.givesQuest != nil {
                    Image(systemName: "exclamationmark.circle.fill")
                } else if choice.action == "heal" {
                    Image(systemName: "heart.fill")
                }
                Text(choice.displayText)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(special ? Color(hex: "#B45CFF").opacity(0.3) : Color(hex: "#2A3350"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(special ? Color(hex: "#B45CFF") : Color.panelBorder, lineWidth: 1)
            )
        }
    }
}

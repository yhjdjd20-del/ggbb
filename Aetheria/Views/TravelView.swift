import SwiftUI

/// Waystone fast travel between activated checkpoints of the current level.
struct TravelView: View {
    @ObservedObject var vm: GameViewModel

    private var stones: [String] {
        let here = Set(vm.scene?.checkpoints.map(\.checkpointId) ?? [])
        return vm.session.waystones.filter { here.contains($0) }
    }

    var body: some View {
        ZStack {
            FullscreenDim()
            Panel(title: L.t("travel.title")) {
                VStack(spacing: 10) {
                    if stones.isEmpty {
                        Text(L.t("travel.empty"))
                            .font(.subheadline)
                            .foregroundColor(.dimText)
                            .multilineTextAlignment(.center)
                    } else {
                        ForEach(Array(stones.enumerated()), id: \.offset) { i, cp in
                            HStack {
                                Text("◆ \(L.t("travel.title")) \(i + 1)")
                                    .foregroundColor(.white)
                                Spacer()
                                if cp == vm.session.checkpointId {
                                    Text(L.t("travel.here"))
                                        .font(.caption)
                                        .foregroundColor(.dimText)
                                } else {
                                    SmallButton(label: L.t("travel.go")) {
                                        vm.showTravel = false
                                        vm.fastTravel(to: cp)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color(hex: "#1E2438"))
                            .cornerRadius(10)
                        }
                    }
                    MenuButton(label: L.t("common.back"), icon: "chevron.left") {
                        vm.showTravel = false
                    }
                }
                .frame(width: 420)
            }
        }
    }
}

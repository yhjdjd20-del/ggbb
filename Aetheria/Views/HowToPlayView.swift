import SwiftUI

/// Controls & goal reference.
struct HowToPlayView: View {
    var onBack: () -> Void

    private let rows: [(icon: String, key: String)] = [
        ("gamecontroller", "howto.move"),
        ("arrow.up", "howto.jump"),
        ("bolt.fill", "howto.attack"),
        ("wind", "howto.dash"),
        ("hand.raised", "howto.interact"),
        ("heart", "howto.potion"),
        ("flag", "howto.goal"),
    ]

    var body: some View {
        HStack {
            Spacer()
            Panel(title: L.t("howto.title")) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(rows, id: \.key) { row in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: row.icon)
                                .foregroundColor(Color(hex: "#7DF9FF"))
                                .frame(width: 28)
                            Text(L.t(row.key))
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                    }
                    MenuButton(label: L.t("common.back"), icon: "chevron.left") {
                        onBack()
                    }
                    .padding(.top, 6)
                }
                .frame(width: 520)
            }
            Spacer()
        }
        .padding()
    }
}

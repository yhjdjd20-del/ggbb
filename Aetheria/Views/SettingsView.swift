import SwiftUI

/// App settings: language, difficulty, audio, haptics, minimap, effects.
struct SettingsView: View {
    var onBack: () -> Void
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        HStack {
            Spacer()
            Panel(title: L.t("set.title")) {
                VStack(spacing: 14) {
                    // Language.
                    HStack {
                        Text(L.t("set.language"))
                            .foregroundColor(.dimText)
                        Spacer()
                        Picker("", selection: $settings.language) {
                            Text("English").tag(AppLanguage.en)
                            Text("Русский").tag(AppLanguage.ru)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                    // Difficulty.
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(L.t("set.difficulty"))
                                .foregroundColor(.dimText)
                            Spacer()
                            Picker("", selection: $settings.difficulty) {
                                ForEach(Difficulty.allCases, id: \.self) { diff in
                                    Text(diff.title).tag(diff)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 270)
                        }
                        Text(settings.difficulty.details)
                            .font(.caption)
                            .foregroundColor(.dimText.opacity(0.8))
                    }
                    Divider().background(Color.panelBorder)
                    // Volumes.
                    volumeRow(L.t("set.master"), $settings.masterVolume)
                    volumeRow(L.t("set.music"), $settings.musicVolume)
                    volumeRow(L.t("set.sfx"), $settings.sfxVolume)
                    Divider().background(Color.panelBorder)
                    // Toggles.
                    toggleRow(L.t("set.haptics"), $settings.hapticsEnabled)
                    toggleRow(L.t("set.minimap"), $settings.showMinimap)
                    toggleRow(L.t("set.effects"), $settings.richEffects)
                    toggleRow(L.t("set.shake"), $settings.screenShake)
                    toggleRow(L.t("set.dmgNumbers"), $settings.damageNumbers)
                    toggleRow(L.t("set.autoPotion"), $settings.autoPotion)
                    // Graphics quality.
                    HStack {
                        Text(L.t("set.graphics"))
                            .foregroundColor(.dimText)
                        Spacer()
                        Picker("", selection: $settings.displayQuality) {
                            ForEach(DisplayQuality.allCases, id: \.self) { quality in
                                Text(quality.title).tag(quality)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 270)
                    }
                    Text("\(L.t("set.device")): \(DeviceProfile.marketingName)")
                        .font(.caption)
                        .foregroundColor(.dimText.opacity(0.8))
                    Text(L.t("set.credits"))
                        .font(.caption)
                        .foregroundColor(.dimText.opacity(0.8))
                        .multilineTextAlignment(.center)
                    MenuButton(label: L.t("common.back"), icon: "chevron.left") {
                        onBack()
                    }
                }
                .frame(width: 430)
            }
            Spacer()
        }
        .padding()
    }

    private func volumeRow(_ label: String, _ value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.dimText)
                .frame(width: 150, alignment: .leading)
            Slider(value: value, in: 0...1)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundColor(.dimText)
                .frame(width: 36)
        }
    }

    private func toggleRow(_ label: String, _ value: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.dimText)
            Spacer()
            Toggle("", isOn: value)
                .labelsHidden()
        }
    }
}

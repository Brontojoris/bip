import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultSound") private var defaultSound = "bip-soft"
    @AppStorage("defaultHaptic") private var defaultHapticRaw = BipHaptic.notification.rawValue

    var body: some View {
        Form {
            Section("Defaults") {
                Picker("Default sound", selection: $defaultSound) {
                    ForEach(AudioHapticManager.availableSounds, id: \.id) { s in
                        Text(s.name).tag(s.id)
                    }
                }
                .onChange(of: defaultSound) { AudioHapticManager.shared.playSound(defaultSound) }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Build", value: "1")
            }
        }
        .navigationTitle("Settings")
    }
}

import SwiftUI

struct SettingsView: View {
	@AppStorage("defaultSound") private var defaultSound = "Bip"
	@AppStorage("defaultHaptic") private var defaultHapticRaw = BipHaptic.notification.rawValue

	var body: some View {
		Form {
			Section("Defaults") {
				NavigationLink {
					SoundPickerView(selectedSound: $defaultSound)
				} label: {
					HStack {
						Text("Default sound")
						Spacer()
						Text(AudioHapticManager.availableSounds.first(where: { $0.id == defaultSound })?.name ?? defaultSound)
							.foregroundColor(.secondary)
					}
				}
			}

			Section("About") {
				LabeledContent("Version", value: "1.0")
				LabeledContent("Build", value: "1")
			}
		}
		.navigationTitle("Settings")
	}
}

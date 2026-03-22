import SwiftUI

struct ConfigureView: View {
	@Environment(\.dismiss) var dismiss
	@State private var config: BipTimerConfig
	private let onSave: (BipTimerConfig) -> Void
	@State private var showingAdvanced = false

	@AppStorage("defaultSound") private var defaultSound = "Bip"
	@AppStorage("defaultHaptic") private var defaultHapticRaw = BipHaptic.notification.rawValue

	init(config: BipTimerConfig?, onSave: @escaping (BipTimerConfig) -> Void) {
		_config = State(initialValue: config ?? BipTimerConfig())
		self.onSave = onSave
	}

	var body: some View {
		Form {
			Section("Name") {
				TextField("Timer name", text: $config.name)
			}

			Section("Phases") {
				ForEach($config.phases) { $phase in
					PhaseRowView(phase: $phase)
				}
				.onDelete { config.phases.remove(atOffsets: $0) }
				.onMove { config.phases.move(fromOffsets: $0, toOffset: $1) }

				Button {
					config.phases.append(BipPhase(label: "Phase \(config.phases.count + 1)", duration: 60))
				} label: {
					Label("Add Phase", systemImage: "plus.circle")
				}
			}

			Section("Alert") {
				NavigationLink {
					SoundPickerView(selectedSound: $config.soundID)
				} label: {
					HStack {
						Text("Sound")
						Spacer()
						Text(AudioHapticManager.availableSounds.first(where: { $0.id == config.soundID })?.name ?? config.soundID)
							.foregroundColor(.secondary)
					}
				}

				Picker("Haptic", selection: $config.hapticType) {
					ForEach(BipHaptic.allCases) { h in
						Text(h.displayName).tag(h)
					}
				}
				.onChange(of: config.hapticType) { AudioHapticManager.shared.triggerHaptic(config.hapticType) }
			}

			Section("Repeats") {
				Picker("Repeat", selection: $config.repeatCount) {
					Text("Forever").tag(0)
					ForEach(1...20, id: \.self) { n in
						Text("\(n) \(n == 1 ? "cycle" : "cycles")").tag(n)
					}
				}
			}
		}
		.navigationTitle(config.name.isEmpty ? "New Timer" : config.name)
		.navigationBarTitleDisplayMode(.inline)
		.onAppear {
			// Apply user's default sound/haptic when creating a new timer
			if config.name == "New Timer" {
				config.soundID = defaultSound
				if let haptic = BipHaptic(rawValue: defaultHapticRaw) {
					config.hapticType = haptic
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Cancel") { dismiss() }
			}
			ToolbarItem(placement: .confirmationAction) {
				Button("Save") {
					onSave(config)
					dismiss()
				}
				.disabled(config.name.isEmpty || config.phases.isEmpty)
			}
		}
	}
}

// MARK: - Phase Row
struct PhaseRowView: View {
	@Binding var phase: BipPhase
	@State private var durationMinutes: Double

	init(phase: Binding<BipPhase>) {
		_phase = phase
		_durationMinutes = State(initialValue: phase.wrappedValue.duration / 60)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			TextField("Phase label", text: $phase.label)
				.font(.body)
			HStack {
				Slider(value: $durationMinutes, in: 0.5...120, step: 0.5)
					.onChange(of: durationMinutes) { phase.duration = durationMinutes * 60 }
				Text(formatDuration(phase.duration))
					.font(.system(.caption, design: .monospaced))
					.foregroundStyle(.secondary)
					.frame(width: 56, alignment: .trailing)
			}
		}
		.padding(.vertical, 4)
	}

	private func formatDuration(_ t: TimeInterval) -> String {
		let m = Int(t) / 60
		let s = Int(t) % 60
		if m == 0 { return "\(s)s" }
		if s == 0 { return "\(m)m" }
		return "\(m)m\(s)s"
	}
}

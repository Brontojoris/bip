import SwiftUI

struct HomeView: View {
	@EnvironmentObject var store: BipStore
	@EnvironmentObject var engine: BipEngine
	@State private var showingAdd = false
	@State private var editingConfig: BipTimerConfig?

	var body: some View {
		NavigationStack {
			List {
				if engine.state.isRunning {
					Section("Running") {
						NavigationLink(destination: RunningView()) {
							RunningRowView(state: engine.state)
						}
					}
				}

				Section("Timers") {
					ForEach(store.configs) { config in
						TimerRowView(config: config)
							.contentShape(Rectangle())
							.onTapGesture { startTimer(config) }
							.swipeActions(edge: .trailing) {
								Button(role: .destructive) {
									store.delete(config)
								} label: {
									Label("Delete", systemImage: "trash")
								}
								Button {
									editingConfig = config
								} label: {
									Label("Edit", systemImage: "pencil")
								}
								.tint(.accentColor)
							}
					}
				}
			}
			.navigationTitle("Bip")
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button { showingAdd = true } label: {
						Image(systemName: "plus")
					}
				}
				ToolbarItem(placement: .navigationBarLeading) {
					NavigationLink(destination: SettingsView()) {
						Image(systemName: "gearshape")
					}
				}
			}
			.sheet(isPresented: $showingAdd) {
				NavigationStack {
					ConfigureView(config: nil) { newConfig in
						store.add(newConfig)
					}
				}
			}
			.sheet(item: $editingConfig) { config in
				NavigationStack {
					ConfigureView(config: config) { updated in
						store.update(updated)
					}
				}
			}
		}
	}

	private func startTimer(_ config: BipTimerConfig) {
		// Play sound and haptic immediately when starting
		AudioHapticManager.shared.playSound(config.soundID)
		AudioHapticManager.shared.triggerHaptic(config.hapticType)
		
		engine.start(config: config)
	}
}

// MARK: - Timer Row
struct TimerRowView: View {
	let config: BipTimerConfig

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(config.name)
				.font(.body)
			HStack(spacing: 6) {
				ForEach(config.phases.prefix(4)) { phase in
					Text(phase.label)
						.font(.caption)
						.foregroundStyle(.secondary)
					if phase.id != config.phases.prefix(4).last?.id {
						Text("·").foregroundStyle(.tertiary).font(.caption)
					}
				}
				if config.phases.count > 4 {
					Text("+ \(config.phases.count - 4) more").font(.caption).foregroundStyle(.tertiary)
				}
			}
			Text(formatDuration(config.totalCycleDuration))
				.font(.caption2)
				.foregroundStyle(.tertiary)
		}
		.padding(.vertical, 2)
	}

	private func formatDuration(_ t: TimeInterval) -> String {
		let h = Int(t) / 3600
		let m = (Int(t) % 3600) / 60
		let s = Int(t) % 60
		if h > 0 { return String(format: "%dh %02dm cycle", h, m) }
		if m > 0 { return String(format: "%dm %02ds cycle", m, s) }
		return String(format: "%ds cycle", s)
	}
}

// MARK: - Running Row
struct RunningRowView: View {
	let state: BipSessionState

	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 2) {
				Text(state.configName).font(.body)
				Text(state.currentPhaseLabel).font(.caption).foregroundStyle(.secondary)
			}
			Spacer()
			Text(timeString(state.timeRemaining))
				.font(.system(.title3, design: .monospaced, weight: .medium))
				.foregroundStyle(.primary)
		}
	}

	private func timeString(_ t: TimeInterval) -> String {
		let m = Int(t) / 60
		let s = Int(t) % 60
		return String(format: "%d:%02d", m, s)
	}
}

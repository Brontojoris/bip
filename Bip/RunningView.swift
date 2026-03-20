import SwiftUI

struct RunningView: View {
    @EnvironmentObject var engine: BipEngine
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var body: some View {
        let state = engine.state
        VStack(spacing: 0) {
            // Phase label
            Text(state.currentPhaseLabel)
                .font(.system(.title2, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 24)

            // Countdown
            Text(timeString(state.timeRemaining))
                .font(.system(size: 72, weight: .thin, design: .monospaced))
                .padding(.vertical, 8)

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: state.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: state.progress)
            }
            .frame(width: 200, height: 200)
            .padding(.bottom, 24)

            // Phase sequence
            PhaseSequenceView(state: state)
                .padding(.horizontal)
                .padding(.bottom, 24)

            // Controls
            HStack(spacing: 24) {
                // Stop
                CircleButton(systemImage: "stop.fill", tint: .red) {
                    engine.stop()
                }

                // Play/Pause
                CircleButton(systemImage: state.isPaused ? "play.fill" : "pause.fill", tint: .accentColor, large: true) {
                    state.isPaused ? engine.resume() : engine.pause()
                }

                // Skip
                CircleButton(systemImage: "forward.end.fill", tint: .secondary) {
                    engine.skip()
                }
            }
            .padding(.bottom, 32)

            // Bip log
            if !state.bipLog.isEmpty {
                Divider()
                BipLogView(log: state.bipLog)
                    .frame(maxHeight: 180)
            }
        }
        .navigationTitle(state.configName)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: state) {
            connectivity.sendSessionState(state)
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Phase Sequence
struct PhaseSequenceView: View {
    let state: BipSessionState

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Text(state.cycleCount > 0 ? "Cycle \(state.cycleCount + 1)" : "")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Bip Log
struct BipLogView: View {
    let log: [BipLogEntry]

    var body: some View {
        List(log.reversed()) { entry in
            HStack {
                Text(entry.phaseLabel).font(.caption)
                Spacer()
                Text(entry.timestamp, style: .time).font(.caption).foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Circle Button
struct CircleButton: View {
    let systemImage: String
    var tint: Color = .accentColor
    var large: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: large ? 22 : 16, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: large ? 72 : 52, height: large ? 72 : 52)
                .background(tint.opacity(0.1))
                .clipShape(Circle())
                .overlay(Circle().stroke(tint.opacity(0.2), lineWidth: 1))
        }
    }
}

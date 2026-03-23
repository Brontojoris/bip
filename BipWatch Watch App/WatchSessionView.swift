import SwiftUI
import WatchKit

struct WatchSessionView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @EnvironmentObject var engine: BipEngine

    var state: BipSessionState { connectivity.sessionState }

    var body: some View {
        NavigationStack {
            if state.isRunning {
                runningView
            } else {
                idleView
            }
        }
    }

    // MARK: - Running
    var runningView: some View {
        VStack(spacing: 4) {
            Text(state.configName)
                .font(.system(.caption2, weight: .semibold))
                .foregroundStyle(.red)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(state.currentPhaseLabel)
                .font(.system(.headline, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(timeString(state.timeRemaining))
                .font(.system(size: 44, weight: .thin, design: .monospaced))

            ProgressView(value: state.progress)
                .progressViewStyle(.linear)
                .tint(.accentColor)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                // Stop
                Button {
                    connectivity.sendCommand(WatchMessage.commandStop)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                // Skip
                Button {
                    connectivity.sendCommand(WatchMessage.commandSkip)
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 4)

            NavigationLink(destination: WatchHistoryView()) {
                Text("History")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 4)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Idle
    var idleView: some View {
        VStack(spacing: 8) {
            Image(systemName: "timer")
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(.secondary)
            Text("No timer running")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Start a timer on iPhone")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let m = Int(max(0, t)) / 60
        let s = Int(max(0, t)) % 60
        return String(format: "%d:%02d", m, s)
    }
}

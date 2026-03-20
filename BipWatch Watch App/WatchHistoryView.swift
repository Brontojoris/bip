import SwiftUI

struct WatchHistoryView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    var log: [BipLogEntry] { connectivity.sessionState.bipLog }

    var body: some View {
        List {
            if log.isEmpty {
                Text("No bips yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(log.reversed()) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.phaseLabel)
                            .font(.caption)
                        Text(entry.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Bip Log")
    }
}

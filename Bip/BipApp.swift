import SwiftUI

@main
struct BipApp: App {
    @StateObject private var store = BipStore()
    @StateObject private var engine = BipEngine()
    @StateObject private var connectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .environmentObject(engine)
                .environmentObject(connectivity)
                .onAppear { setupConnectivity() }
        }
    }

    private func setupConnectivity() {
        connectivity.onCommand = { cmd in
            switch cmd {
            case WatchMessage.commandStop:  engine.stop()
            case WatchMessage.commandSkip:  engine.skip()
            case WatchMessage.commandStart:
                if engine.state.isPaused { engine.resume() }
            default: break
            }
        }
        engine.onBip = { state in
            connectivity.sendSessionState(state)
        }
    }
}

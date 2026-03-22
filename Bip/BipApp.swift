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
				.onAppear { setupEngine() }
		}
	}

	private func setupEngine() {
		connectivity.onCommand = { [self] cmd in
			switch cmd {
			case WatchMessage.commandStop:  engine.stop()
			case WatchMessage.commandSkip:  engine.skip()
			case WatchMessage.commandStart:
				if engine.state.isPaused { engine.resume() }
			default: break
			}
		}
		
		// Set up callback to play sound and haptic when phases complete
		engine.onBip = { state, config in
			connectivity.sendSessionState(state)
			AudioHapticManager.shared.playSound(config.soundID)
			AudioHapticManager.shared.triggerHaptic(config.hapticType)
		}
	}
}

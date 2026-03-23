import SwiftUI
import UIKit

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
				.task {
					BipNotificationManager.shared.requestPermission()
					setupCallbacks()
				}
		}
	}

	private func setupCallbacks() {
		let notifications = BipNotificationManager.shared

		// Phase transition: play audio/haptic and reschedule remaining notifications
		engine.onBip = { [connectivity] state, config in
			connectivity.sendSessionState(state)
			AudioHapticManager.shared.playSound(config.soundID)
			AudioHapticManager.shared.triggerHaptic(config.hapticType)
			notifications.schedulePhaseNotifications(config: config, state: state)
		}

		// Timer started: schedule all upcoming notifications and request background time
		engine.onStart = { [connectivity] state, config in
			connectivity.sendSessionState(state)
			notifications.schedulePhaseNotifications(config: config, state: state)
			Self.beginBackgroundTask()
		}

		// Timer stopped: cancel pending notifications
		engine.onStop = {
			notifications.cancelAll()
		}

		connectivity.onCommand = { [engine] cmd in
			switch cmd {
			case WatchMessage.commandStop:  engine.stop()
			case WatchMessage.commandSkip:  engine.skip()
			case WatchMessage.commandStart:
				if engine.state.isPaused { engine.resume() }
			default: break
			}
		}
	}

	// MARK: - Background task grace period

	private static var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

	private static func beginBackgroundTask() {
		guard backgroundTaskID == .invalid else { return }
		backgroundTaskID = UIApplication.shared.beginBackgroundTask {
			endBackgroundTask()
		}
	}

	private static func endBackgroundTask() {
		guard backgroundTaskID != .invalid else { return }
		UIApplication.shared.endBackgroundTask(backgroundTaskID)
		backgroundTaskID = .invalid
	}
}

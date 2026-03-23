import Foundation
import UserNotifications

#if os(iOS)
import UIKit
#endif

/// Schedules local notifications for upcoming phase transitions so that
/// alerts fire even when the app is suspended in the background.
public class BipNotificationManager {
	public static let shared = BipNotificationManager()
	private let center = UNUserNotificationCenter.current()
	private static let categoryID = "BIP_PHASE_TRANSITION"
	private static let identifierPrefix = "bip-phase-"

	/// Tracks identifiers from the current batch so cancelAll can target them.
	private var scheduledIdentifiers: [String] = []

	private init() {}

	// MARK: - Permission

	public func requestPermission() {
		center.requestAuthorization(options: [.alert, .sound]) { granted, error in
			if let error = error {
				print("⚠️ Notification permission error: \(error.localizedDescription)")
			}
		}
	}

	// MARK: - Schedule notifications for all upcoming phase transitions

	/// Call when a timer starts or when timing changes (skip/pause/resume).
	/// Cancels any existing scheduled notifications and re-schedules from the current state.
	public func schedulePhaseNotifications(config: BipTimerConfig, state: BipSessionState) {
		// Remove previous batch by their specific identifiers
		if !scheduledIdentifiers.isEmpty {
			center.removePendingNotificationRequests(withIdentifiers: scheduledIdentifiers)
			scheduledIdentifiers = []
		}

		guard state.isRunning, !state.isPaused else { return }

		// Unique batch ID avoids collisions with async removal of prior batch
		let batchID = UUID().uuidString.prefix(8)
		let now = Date()
		var offset: TimeInterval = state.timeRemaining // time until current phase ends

		// Collect all upcoming transition times
		var notifications: [(fireDate: Date, phaseLabel: String, soundID: String)] = []

		// Remaining phases in current cycle
		let phasesInCurrentCycle = config.phases.suffix(from: state.currentPhaseIndex + 1)

		// First transition: end of current phase
		if offset > 0 {
			let nextLabel = phasesInCurrentCycle.first?.label ?? config.phases.first?.label ?? "Next"
			notifications.append((now.addingTimeInterval(offset), nextLabel, config.soundID))
		}

		// Remaining phases in current cycle
		for (i, phase) in phasesInCurrentCycle.enumerated() {
			offset += phase.duration
			let nextIndex = state.currentPhaseIndex + 1 + i + 1
			let nextLabel: String
			if nextIndex < config.phases.count {
				nextLabel = config.phases[nextIndex].label
			} else {
				nextLabel = config.phases.first?.label ?? "Done"
			}
			notifications.append((now.addingTimeInterval(offset), nextLabel, config.soundID))
		}

		// Additional full cycles (up to a reasonable limit)
		let infiniteRepeat = config.repeatCount == 0
		let remainingCycles: Int
		if infiniteRepeat {
			remainingCycles = min(10, 64 / max(config.phases.count, 1))
		} else {
			remainingCycles = max(0, config.repeatCount - state.cycleCount - 1)
		}

		for _ in 0..<remainingCycles {
			for (i, phase) in config.phases.enumerated() {
				offset += phase.duration
				let nextLabel: String
				if i + 1 < config.phases.count {
					nextLabel = config.phases[i + 1].label
				} else {
					nextLabel = config.phases.first?.label ?? "Done"
				}
				notifications.append((now.addingTimeInterval(offset), nextLabel, config.soundID))
			}
		}

		// iOS caps at 64 pending notifications
		let capped = notifications.prefix(60)
		var newIdentifiers: [String] = []

		for (index, notif) in capped.enumerated() {
			let content = UNMutableNotificationContent()
			content.title = "Bip"
			content.body = notif.phaseLabel
			content.sound = notificationSound(for: notif.soundID)
			content.categoryIdentifier = Self.categoryID

			let trigger = UNTimeIntervalNotificationTrigger(
				timeInterval: max(1, notif.fireDate.timeIntervalSince(now)),
				repeats: false
			)

			let identifier = "\(Self.identifierPrefix)\(batchID)-\(index)"
			newIdentifiers.append(identifier)

			let request = UNNotificationRequest(
				identifier: identifier,
				content: content,
				trigger: trigger
			)

			center.add(request)
		}

		scheduledIdentifiers = newIdentifiers
	}

	// MARK: - Cancel

	public func cancelAll() {
		if !scheduledIdentifiers.isEmpty {
			center.removePendingNotificationRequests(withIdentifiers: scheduledIdentifiers)
			scheduledIdentifiers = []
		}
		// Also catch any stragglers
		center.removeAllPendingNotificationRequests()
	}

	// MARK: - Sound mapping

	private func notificationSound(for soundID: String) -> UNNotificationSound {
		if Bundle.main.url(forResource: soundID, withExtension: "wav") != nil {
			return UNNotificationSound(named: UNNotificationSoundName("\(soundID).wav"))
		}
		if Bundle.main.url(forResource: soundID, withExtension: "caf") != nil {
			return UNNotificationSound(named: UNNotificationSoundName("\(soundID).caf"))
		}
		return .default
	}
}

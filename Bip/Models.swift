import Foundation
import SwiftUI
import Combine

// MARK: - Constants
let APP_GROUP_ID = "group.com.jorisdebeer.Bip"

// MARK: - Phase Model
public struct BipPhase: Identifiable, Codable, Hashable {
	public var id: UUID = UUID()
	public var label: String
	public var duration: TimeInterval // seconds

	public init(label: String, duration: TimeInterval) {
		self.label = label
		self.duration = duration
	}

	public static func defaultWorkRest(work: TimeInterval = 25 * 60, rest: TimeInterval = 5 * 60) -> [BipPhase] {
		[BipPhase(label: "Work", duration: work),
		 BipPhase(label: "Rest", duration: rest)]
	}
}

// MARK: - Timer Config
public struct BipTimerConfig: Identifiable, Codable, Hashable {
	public var id: UUID = UUID()
	public var name: String
	public var phases: [BipPhase]
	public var repeatCount: Int  // 0 = infinite
	public var soundID: String   // filename without extension, e.g. "bip-soft"
	public var hapticType: BipHaptic

	public init(name: String = "New Timer",
				phases: [BipPhase] = BipPhase.defaultWorkRest(),
				repeatCount: Int = 0,
				soundID: String = "Bip",
				hapticType: BipHaptic = .notification) {
		self.name = name
		self.phases = phases
		self.repeatCount = repeatCount
		self.soundID = soundID
		self.hapticType = hapticType
	}

	public var totalCycleDuration: TimeInterval {
		phases.reduce(0) { $0 + $1.duration }
	}
}

// MARK: - Haptic Type
public enum BipHaptic: String, Codable, CaseIterable, Identifiable {
	case notification, start, stop, success, retry, click

	public var id: String { rawValue }

	public var displayName: String {
		switch self {
		case .notification: return "Notification"
		case .start:        return "Start"
		case .stop:         return "Stop"
		case .success:      return "Success"
		case .retry:        return "Retry"
		case .click:        return "Click"
		}
	}
}

// MARK: - Session State (shared phone <-> watch)
public struct BipSessionState: Codable, Equatable {
	public var configID: UUID
	public var configName: String
	public var isRunning: Bool
	public var isPaused: Bool
	public var currentPhaseIndex: Int
	public var currentPhaseLabel: String
	public var currentPhaseElapsed: TimeInterval
	public var currentPhaseDuration: TimeInterval
	public var cycleCount: Int
	public var totalRepeatCount: Int
	public var bipLog: [BipLogEntry]
	public var startedAt: Date?

	public var timeRemaining: TimeInterval {
		max(0, currentPhaseDuration - currentPhaseElapsed)
	}

	public var progress: Double {
		guard currentPhaseDuration > 0 else { return 0 }
		return currentPhaseElapsed / currentPhaseDuration
	}

	public static var empty: BipSessionState {
		BipSessionState(configID: UUID(), configName: "", isRunning: false, isPaused: false,
						currentPhaseIndex: 0, currentPhaseLabel: "", currentPhaseElapsed: 0,
						currentPhaseDuration: 0, cycleCount: 0, totalRepeatCount: 0,
						bipLog: [], startedAt: nil)
	}
}

// MARK: - Bip Log Entry
public struct BipLogEntry: Codable, Identifiable, Equatable {
	public var id: UUID = UUID()
	public var timestamp: Date
	public var phaseLabel: String
	public var cycleNumber: Int
}

// MARK: - Watch Message Keys
public enum WatchMessage {
	static let sessionState = "sessionState"
	static let command = "command"
	static let commandStart = "start"
	static let commandStop = "stop"
	static let commandSkip = "skip"
	static let configData = "configData"
}

// MARK: - Storage
public class BipStore: ObservableObject {
	@Published public var configs: [BipTimerConfig] = []

	private let defaults: UserDefaults

	public init() {
		defaults = UserDefaults(suiteName: APP_GROUP_ID) ?? .standard
		load()
		if configs.isEmpty { addSampleConfigs() }
	}

	public func save() {
		if let data = try? JSONEncoder().encode(configs) {
			defaults.set(data, forKey: "bipConfigs")
		}
	}

	private func load() {
		guard let data = defaults.data(forKey: "bipConfigs"),
			  let decoded = try? JSONDecoder().decode([BipTimerConfig].self, from: data) else { return }
		configs = decoded
	}

	public func add(_ config: BipTimerConfig) {
		configs.append(config)
		save()
	}

	public func update(_ config: BipTimerConfig) {
		if let idx = configs.firstIndex(where: { $0.id == config.id }) {
			configs[idx] = config
			save()
		}
	}

	public func delete(_ config: BipTimerConfig) {
		configs.removeAll { $0.id == config.id }
		save()
	}

	private func addSampleConfigs() {
		configs = [
			BipTimerConfig(name: "Hockey Game", phases: [
				BipPhase(label: "First Half", duration: 25 * 60),
				BipPhase(label: "Half Time", duration: 5 * 60),
				BipPhase(label: "Second Half", duration: 25 * 60)
			], repeatCount: 1),
			BipTimerConfig(name: "Gym Sets", phases: [
				BipPhase(label: "Work", duration: 50),
				BipPhase(label: "Rest", duration: 100)
			], repeatCount: 3),
			BipTimerConfig(name: "Quick Intervals", phases: BipPhase.defaultWorkRest(work: 10 * 60, rest: 2 * 60))
		]
		save()
	}
}

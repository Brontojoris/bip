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
	
	// Custom Codable implementation to handle old data without soundID/hapticType
	enum CodingKeys: String, CodingKey {
		case id, name, phases, repeatCount, soundID, hapticType
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		name = try container.decode(String.self, forKey: .name)
		phases = try container.decode([BipPhase].self, forKey: .phases)
		repeatCount = try container.decode(Int.self, forKey: .repeatCount)
		// Provide defaults for new fields if they don't exist
		soundID = try container.decodeIfPresent(String.self, forKey: .soundID) ?? "Bip"
		hapticType = try container.decodeIfPresent(BipHaptic.self, forKey: .hapticType) ?? .notification
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
	public var soundID: String
	public var hapticType: BipHaptic
	
	// Custom Codable implementation to handle old data without soundID/hapticType
	enum CodingKeys: String, CodingKey {
		case configID, configName, isRunning, isPaused, currentPhaseIndex
		case currentPhaseLabel, currentPhaseElapsed, currentPhaseDuration
		case cycleCount, totalRepeatCount, bipLog, startedAt, soundID, hapticType
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		configID = try container.decode(UUID.self, forKey: .configID)
		configName = try container.decode(String.self, forKey: .configName)
		isRunning = try container.decode(Bool.self, forKey: .isRunning)
		isPaused = try container.decode(Bool.self, forKey: .isPaused)
		currentPhaseIndex = try container.decode(Int.self, forKey: .currentPhaseIndex)
		currentPhaseLabel = try container.decode(String.self, forKey: .currentPhaseLabel)
		currentPhaseElapsed = try container.decode(TimeInterval.self, forKey: .currentPhaseElapsed)
		currentPhaseDuration = try container.decode(TimeInterval.self, forKey: .currentPhaseDuration)
		cycleCount = try container.decode(Int.self, forKey: .cycleCount)
		totalRepeatCount = try container.decode(Int.self, forKey: .totalRepeatCount)
		bipLog = try container.decode([BipLogEntry].self, forKey: .bipLog)
		startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
		// Provide defaults for new fields if they don't exist
		soundID = try container.decodeIfPresent(String.self, forKey: .soundID) ?? "Bip"
		hapticType = try container.decodeIfPresent(BipHaptic.self, forKey: .hapticType) ?? .notification
	}
	
	public init(configID: UUID, configName: String, isRunning: Bool, isPaused: Bool,
				currentPhaseIndex: Int, currentPhaseLabel: String, currentPhaseElapsed: TimeInterval,
				currentPhaseDuration: TimeInterval, cycleCount: Int, totalRepeatCount: Int,
				bipLog: [BipLogEntry], startedAt: Date?, soundID: String, hapticType: BipHaptic) {
		self.configID = configID
		self.configName = configName
		self.isRunning = isRunning
		self.isPaused = isPaused
		self.currentPhaseIndex = currentPhaseIndex
		self.currentPhaseLabel = currentPhaseLabel
		self.currentPhaseElapsed = currentPhaseElapsed
		self.currentPhaseDuration = currentPhaseDuration
		self.cycleCount = cycleCount
		self.totalRepeatCount = totalRepeatCount
		self.bipLog = bipLog
		self.startedAt = startedAt
		self.soundID = soundID
		self.hapticType = hapticType
	}

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
						bipLog: [], startedAt: nil, soundID: "Bip", hapticType: .notification)
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
	private let iCloud = NSUbiquitousKeyValueStore.default
	private static let configsKey = "bipConfigs"
	private let configVersion = 2 // Increment to force reset

	public init() {
		defaults = UserDefaults(suiteName: APP_GROUP_ID) ?? .standard
		// Load on background thread to avoid blocking UI with app group I/O
		let defaults = self.defaults
		let iCloud = self.iCloud
		let configVersion = self.configVersion
		DispatchQueue.global(qos: .userInitiated).async {
			// Version check
			let savedVersion = defaults.integer(forKey: "configVersion")
			if savedVersion < configVersion {
				defaults.removeObject(forKey: Self.configsKey)
				defaults.set(configVersion, forKey: "configVersion")
			}
			// Load configs: prefer iCloud, fall back to local UserDefaults
			var configs: [BipTimerConfig] = []
			if let iCloudData = iCloud.data(forKey: Self.configsKey),
			   let decoded = try? JSONDecoder().decode([BipTimerConfig].self, from: iCloudData),
			   !decoded.isEmpty {
				configs = decoded
			} else if let localData = defaults.data(forKey: Self.configsKey),
					  let decoded = try? JSONDecoder().decode([BipTimerConfig].self, from: localData) {
				configs = decoded
				// Migrate existing local data up to iCloud
				if let data = try? JSONEncoder().encode(configs) {
					iCloud.set(data, forKey: Self.configsKey)
					iCloud.synchronize()
				}
			}
			// Generate samples on first launch
			if configs.isEmpty {
				configs = Self.makeSampleConfigs()
				if let data = try? JSONEncoder().encode(configs) {
					defaults.set(data, forKey: Self.configsKey)
					iCloud.set(data, forKey: Self.configsKey)
					iCloud.synchronize()
				}
			}
			DispatchQueue.main.async {
				self.configs = configs
			}
		}
		// Listen for iCloud changes from other devices
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(iCloudDidChange(_:)),
			name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
			object: iCloud
		)
		iCloud.synchronize()
	}

	@objc private func iCloudDidChange(_ notification: Notification) {
		guard let data = iCloud.data(forKey: Self.configsKey),
			  let decoded = try? JSONDecoder().decode([BipTimerConfig].self, from: data),
			  !decoded.isEmpty else { return }
		DispatchQueue.main.async {
			self.configs = decoded
			// Keep local UserDefaults in sync
			self.defaults.set(data, forKey: Self.configsKey)
		}
	}

	public func save() {
		if let data = try? JSONEncoder().encode(configs) {
			defaults.set(data, forKey: Self.configsKey)
			iCloud.set(data, forKey: Self.configsKey)
			iCloud.synchronize()
		}
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

	private static func makeSampleConfigs() -> [BipTimerConfig] {
		[
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
	}
}

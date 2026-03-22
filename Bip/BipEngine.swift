import Foundation
import Combine

// MARK: - BipEngine
// Core timer engine. Shared between iOS and watchOS.
// On iOS: kept alive via BGTaskScheduler / UIApplication.beginBackgroundTask
// On watchOS: kept alive via WKExtendedRuntimeSession (caller's responsibility)

public class BipEngine: ObservableObject {
	@Published public var state: BipSessionState = .empty

	private var config: BipTimerConfig?
	private var timer: Timer?
	private var tickInterval: TimeInterval = 0.5

	public var onBip: ((BipSessionState, BipTimerConfig) -> Void)?
	public var onComplete: (() -> Void)?

	public init() {}

	// MARK: Start
	public func start(config: BipTimerConfig) {
		self.config = config
		state = BipSessionState(
			configID: config.id,
			configName: config.name,
			isRunning: true,
			isPaused: false,
			currentPhaseIndex: 0,
			currentPhaseLabel: config.phases.first?.label ?? "",
			currentPhaseElapsed: 0,
			currentPhaseDuration: config.phases.first?.duration ?? 0,
			cycleCount: 0,
			totalRepeatCount: config.repeatCount,
			bipLog: [],
			startedAt: Date(),
			soundID: config.soundID,
			hapticType: config.hapticType
		)
		scheduleTimer()
	}

	// MARK: Stop
	public func stop() {
		timer?.invalidate()
		timer = nil
		state.isRunning = false
		state.isPaused = false
	}

	// MARK: Pause / Resume
	public func pause() {
		guard state.isRunning, !state.isPaused else { return }
		timer?.invalidate()
		timer = nil
		state.isPaused = true
	}

	public func resume() {
		guard state.isRunning, state.isPaused else { return }
		state.isPaused = false
		scheduleTimer()
	}

	// MARK: Skip to next phase
	public func skip() {
		guard state.isRunning else { return }
		advancePhase()
	}

	// MARK: Timer tick
	private func scheduleTimer() {
		timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
			self?.tick()
		}
		RunLoop.current.add(timer!, forMode: .common)
	}

	private func tick() {
		guard state.isRunning, !state.isPaused else { return }
		_ = state.currentPhaseElapsed
		state.currentPhaseElapsed += tickInterval

		if state.currentPhaseElapsed >= state.currentPhaseDuration {
			advancePhase()
		}
	}

	private func advancePhase() {
		guard let config = config else { return }

		// Log the bip
		let entry = BipLogEntry(timestamp: Date(),
								 phaseLabel: state.currentPhaseLabel,
								 cycleNumber: state.cycleCount + 1)
		state.bipLog.append(entry)
		onBip?(state, config)

		// Move to next phase
		let nextIndex = state.currentPhaseIndex + 1

		if nextIndex < config.phases.count {
			// Still phases left in this cycle
			state.currentPhaseIndex = nextIndex
			state.currentPhaseLabel = config.phases[nextIndex].label
			state.currentPhaseDuration = config.phases[nextIndex].duration
			state.currentPhaseElapsed = 0
		} else {
			// Completed a full cycle
			state.cycleCount += 1
			let infiniteRepeat = config.repeatCount == 0
			let hasMoreCycles = state.cycleCount < config.repeatCount

			if infiniteRepeat || hasMoreCycles {
				// Start next cycle
				state.currentPhaseIndex = 0
				state.currentPhaseLabel = config.phases[0].label
				state.currentPhaseDuration = config.phases[0].duration
				state.currentPhaseElapsed = 0
			} else {
				// All done
				stop()
				onComplete?()
			}
		}
	}

	// MARK: Restore from shared state (watch resuming)
	public func restore(state: BipSessionState, config: BipTimerConfig) {
		self.config = config
		self.state = state
		if state.isRunning && !state.isPaused {
			scheduleTimer()
		}
	}
}

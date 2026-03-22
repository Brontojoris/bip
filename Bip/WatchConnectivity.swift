#if canImport(WatchConnectivity)
import WatchConnectivity
import Foundation
import Combine

public class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
	public static let shared = WatchConnectivityManager()

	@Published public var sessionState: BipSessionState = .empty
	@Published public var isReachable: Bool = false

	public var onCommand: ((String) -> Void)?
	private var isActivated = false

	private override init() {
		super.init()
		// Defer activation to avoid blocking app startup
		DispatchQueue.main.async {
			self.activateIfNeeded()
		}
	}
	
	private func activateIfNeeded() {
		guard !isActivated, WCSession.isSupported() else { return }
		isActivated = true
		WCSession.default.delegate = self
		WCSession.default.activate()
	}

	// MARK: Send state from phone to watch
	public func sendSessionState(_ state: BipSessionState) {
		guard WCSession.default.isReachable else {
			// Use application context as fallback (delivered when watch wakes)
			if let data = try? JSONEncoder().encode(state) {
				try? WCSession.default.updateApplicationContext([WatchMessage.sessionState: data])
			}
			return
		}
		if let data = try? JSONEncoder().encode(state) {
			WCSession.default.sendMessage([WatchMessage.sessionState: data], replyHandler: nil) { error in
				// Fallback to application context if sendMessage fails
				if let data = try? JSONEncoder().encode(state) {
					try? WCSession.default.updateApplicationContext([WatchMessage.sessionState: data])
				}
			}
		}
	}

	// MARK: Send command from watch to phone
	public func sendCommand(_ command: String) {
		guard WCSession.default.isReachable else { return }
		WCSession.default.sendMessage([WatchMessage.command: command], replyHandler: nil)
	}

	// MARK: WCSessionDelegate
	public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		DispatchQueue.main.async { self.isReachable = session.isReachable }
	}

	public func sessionReachabilityDidChange(_ session: WCSession) {
		DispatchQueue.main.async { self.isReachable = session.isReachable }
	}

	public func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
		DispatchQueue.main.async {
			if let data = message[WatchMessage.sessionState] as? Data,
			   let state = try? JSONDecoder().decode(BipSessionState.self, from: data) {
				self.sessionState = state
			}
			if let cmd = message[WatchMessage.command] as? String {
				self.onCommand?(cmd)
			}
		}
	}

	public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
		DispatchQueue.main.async {
			if let cmd = userInfo[WatchMessage.command] as? String {
				self.onCommand?(cmd)
			}
		}
	}

	public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
		DispatchQueue.main.async {
			if let data = applicationContext[WatchMessage.sessionState] as? Data,
			   let state = try? JSONDecoder().decode(BipSessionState.self, from: data) {
				self.sessionState = state
			}
		}
	}

	#if os(iOS)
	public func sessionDidBecomeInactive(_ session: WCSession) {}
	public func sessionDidDeactivate(_ session: WCSession) { session.activate() }
	#endif
}
#endif

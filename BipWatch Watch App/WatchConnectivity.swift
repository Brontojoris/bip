#if canImport(WatchConnectivity)
import WatchConnectivity
import Foundation
import Combine

public class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    public static let shared = WatchConnectivityManager()

    @Published public var sessionState: BipSessionState = .empty
    @Published public var isReachable: Bool = false

    public var onCommand: ((String) -> Void)?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
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
            WCSession.default.sendMessage([WatchMessage.sessionState: data], replyHandler: nil)
        }
    }

    // MARK: Send command from watch to phone
    public func sendCommand(_ command: String) {
        guard WCSession.default.isReachable else {
            // Queue command for delivery when phone becomes reachable
            WCSession.default.transferUserInfo([WatchMessage.command: command])
            return
        }
        WCSession.default.sendMessage([WatchMessage.command: command], replyHandler: nil) { error in
            // Fallback to transferUserInfo if sendMessage fails
            WCSession.default.transferUserInfo([WatchMessage.command: command])
        }
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

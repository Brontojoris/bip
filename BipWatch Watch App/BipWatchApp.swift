import SwiftUI
import WatchKit

@main
struct BipWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    @StateObject private var engine = BipEngine()
    @WKApplicationDelegateAdaptor private var appDelegate: BipWatchDelegate

    var body: some Scene {
        WindowGroup {
            WatchSessionView()
                .environmentObject(connectivity)
                .environmentObject(engine)
        }
    }
}

class BipWatchDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {}
}

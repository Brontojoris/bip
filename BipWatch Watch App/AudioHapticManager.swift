import Foundation
import AVFoundation
import Combine
#if os(watchOS)
import WatchKit
#else
import UIKit
#endif

public class AudioHapticManager: ObservableObject {
    public static let shared = AudioHapticManager()
    private var audioPlayer: AVAudioPlayer?

    private init() {}

    // MARK: - Play bip sound
    public func playSound(_ soundID: String) {
        guard let url = Bundle.main.url(forResource: soundID, withExtension: "wav") ??
                        Bundle.main.url(forResource: soundID, withExtension: "caf") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {}
    }

    // MARK: - Trigger haptic
    public func triggerHaptic(_ type: BipHaptic) {
        #if os(watchOS)
        triggerWatchHaptic(type)
        #else
        triggerPhoneHaptic(type)
        #endif
    }

    #if os(watchOS)
    private func triggerWatchHaptic(_ type: BipHaptic) {
        let hapticType: WKHapticType
        switch type {
        case .notification: hapticType = .notification
        case .start:        hapticType = .start
        case .stop:         hapticType = .stop
        case .success:      hapticType = .success
        case .retry:        hapticType = .retry
        case .click:        hapticType = .click
        }
        WKInterfaceDevice.current().play(hapticType)
    }
    #else
    private func triggerPhoneHaptic(_ type: BipHaptic) {
        switch type {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .notification, .start:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .stop:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .retry:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .click:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    #endif

    // MARK: - Available sounds
    public static let availableSounds: [(id: String, name: String)] = [
        ("bip-soft",  "Soft Bip"),
        ("bip-bell",  "Bell"),
        ("bip-click", "Click"),
    ]
}

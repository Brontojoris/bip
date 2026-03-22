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
	private var audioSessionConfigured = false
	
	#if !os(watchOS)
	private let notificationGenerator = UINotificationFeedbackGenerator()
	private let impactGeneratorLight = UIImpactFeedbackGenerator(style: .light)
	private let impactGeneratorMedium = UIImpactFeedbackGenerator(style: .medium)
	private let impactGeneratorHeavy = UIImpactFeedbackGenerator(style: .heavy)
	#endif

	private init() {
		#if !os(watchOS)
		// Prepare generators for better performance
		notificationGenerator.prepare()
		impactGeneratorLight.prepare()
		impactGeneratorMedium.prepare()
		impactGeneratorHeavy.prepare()
		#endif
		
		// Configure audio session once at startup
		configureAudioSession()
	}
	
	private func configureAudioSession() {
		guard !audioSessionConfigured else { return }
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
			try AVAudioSession.sharedInstance().setActive(true)
			audioSessionConfigured = true
		} catch {
			print("⚠️ Error configuring audio session: \(error.localizedDescription)")
		}
	}

	// MARK: - Play bip sound
	public func playSound(_ soundID: String) {
		guard let url = Bundle.main.url(forResource: soundID, withExtension: "wav") ??
						Bundle.main.url(forResource: soundID, withExtension: "caf") else {
			print("⚠️ Sound file not found: \(soundID)")
			return
		}
		do {
			audioPlayer = try AVAudioPlayer(contentsOf: url)
			audioPlayer?.play()
		} catch {
			print("⚠️ Error playing sound: \(error.localizedDescription)")
		}
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
			notificationGenerator.notificationOccurred(.success)
			notificationGenerator.prepare()
		case .notification, .start:
			impactGeneratorHeavy.impactOccurred()
			impactGeneratorHeavy.prepare()
		case .stop:
			notificationGenerator.notificationOccurred(.warning)
			notificationGenerator.prepare()
		case .retry:
			impactGeneratorMedium.impactOccurred()
			impactGeneratorMedium.prepare()
		case .click:
			impactGeneratorLight.impactOccurred()
			impactGeneratorLight.prepare()
		}
	}
	#endif

	// MARK: - Available sounds
	public static let availableSounds: [(id: String, name: String)] = [
		("Bip",       "Bip"),
		("Blep",      "Blep"),
		("Bloop",     "Bloop"),
		("Bop",       "Bop"),
		("Done",      "Done"),
		("Go",        "Go"),
		("Pew Pew",   "Pew Pew"),
		("Rest",      "Rest"),
	]
}

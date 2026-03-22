# AGENTS.md — Bip Codebase Guide

## Project Overview

**Bip** is a iOS + watchOS timer app with configurable phases and audio/haptic alerts. Core use cases: fitness intervals, cooking timers, sports game timing. Users configure phase sequences (e.g., 25min Work → 5min Rest) that repeat or stop after N cycles, triggering sound + haptic feedback on each transition.

**Key requirements:** Sticks closely to Apple Human Interface Guidelines; requires device testing (haptics don't work well in simulator).

## Architecture Essentials

### Shared Model Layer (`Bip/Models.swift` + `BipWatch Watch App/Models.swift`)

**Data models are duplicated in both iOS & watchOS targets** to maintain independence when watch disconnects. Keep them synchronized.

- **`BipPhase`**: Individual timer segment (label + duration in seconds). Custom labels supported ("Work", "Rest", "First Half", etc.).
- **`BipTimerConfig`**: Complete timer setup with array of phases, repeat count (0 = infinite), sound/haptic preferences. Codable for persistence via UserDefaults.
- **`BipSessionState`**: Live runtime state synced phone ↔ watch (running/paused, current phase index, elapsed time, bip log). Computed properties: `timeRemaining`, `progress`.
- **`BipStore`**: Persists configs via App Group UserDefaults (`group.com.jorisdebeer.Bip` — **update APP_GROUP_ID if changing bundle ID**). Auto-loads sample configs on empty install.

### Timer Engine (`BipEngine.swift`)

**Runs independently on both platforms.** Core ticker fires every 0.5 seconds; advances phase when elapsed time exceeds phase duration.

```
start(config) → state.isRunning = true
tick() loop → currentPhaseElapsed += 0.5
phase complete? → advancePhase() → emit onBip callback → onComplete() when finished
```

**Key insight:** Engine doesn't trigger sounds/haptics itself—that's delegated to callbacks (`onBip`, `onComplete`). The app setup (BipApp.swift) wires the callbacks to actually play audio/haptics.

**Commands:** `start()`, `pause()`, `resume()`, `skip()`, `stop()`

### Cross-Platform Connectivity

**`WatchConnectivityManager.swift`** (iOS & watchOS)
- Singleton managing WCSession for phone ↔ watch messaging
- Phone sends `BipSessionState` to watch every tick (via `sendSessionState`)
- Watch sends commands back (`start`, `stop`, `skip`) when reachable
- **Fallback:** Uses `applicationContext` when watch unreachable (watch reads state on wake)

**`WatchMessage` enum:** Defines message keys (`sessionState`, `command`, `commandStart`, etc.)

**Watch-side lifecycle:** `BipWatchDelegate` minimal—just launches the app. Real state updates come via WCSession.

### Audio & Haptic Feedback (`AudioHapticManager.swift`)

**Conditional compilation** for iOS vs watchOS:
- **iOS:** Uses `UINotificationFeedbackGenerator` + `UIImpactFeedbackGenerator` (prepared on init for performance)
- **watchOS:** Uses `WKHapticType` (limited selection: notification, start, stop, success, retry, click)

**Sound playback:** Searches for sound files in Bundle (`bip-soft.wav`, `bip-bell.wav`, `bip-click.wav`) or falls back to haptic-only if missing.

## Critical Developer Workflows

### Build & Run

**iOS:** Standard Xcode build. Ensure App Group capability signed (Signing & Capabilities → App Groups).

**watchOS:** 
1. Add watchOS target via File → New → Target → Watch App
2. **Enable Background Mode:** watchOS target → Signing & Capabilities → Background Modes → "Workout Processing"
3. Copy shared models to both targets
4. Test on device (simulator haptics are nearly useless)

### Persistence & Syncing

- **Configs stored** in App Group UserDefaults (`UserDefaults(suiteName: APP_GROUP_ID)`)
- **Phone loads/saves** via `BipStore` (called on init, after add/update/delete)
- **Watch reads** from same UserDefaults—no explicit sync needed
- **Live session state** synced via WatchConnectivity (not persisted; recreated each run)

### Testing Tips

- Most logic in `BipEngine` is platform-agnostic; test ticker math separately
- Audio/haptic methods are no-op in unit tests; mock `onBip` callback
- Use sample configs in `BipStore.addSampleConfigs()` as test data
- WatchConnectivity can be stubbed in unit tests

## Project-Specific Patterns & Conventions

### SwiftUI Views Hierarchy

- **HomeView:** Main list of saved configs; shows active running timer as top section
- **ConfigureView:** Edit/create config (phases, name, sound/haptic settings) with advanced toggles
- **RunningView:** Active timer display during countdown
- **WatchSessionView:** Watch app main view (observes `connectivity.sessionState` for live updates)
- **SettingsView:** Global app preferences

**Convention:** Views are `struct` (not `final class`); use `@EnvironmentObject` to inject `BipStore`, `BipEngine`, `WatchConnectivityManager` via `BipApp.swift` setup.

### Identifiable & Codable Everywhere

All models conform to both `Identifiable` (for ForEach in SwiftUI) and `Codable` (for persistence). Keep this when adding new fields.

### Time Representation

- **Durations:** Stored as `TimeInterval` (seconds, Double). Display with formatters where needed.
- **Elapsed tracking:** Ticker increments `currentPhaseElapsed` by tickInterval (0.5s). Phase completes when `elapsed ≥ duration`.

### App Group Constant

**All references to app group ID use `APP_GROUP_ID` constant in Models.swift.** If changing bundle prefix:
1. Update `APP_GROUP_ID = "group.com.yourname.Bip"`
2. Update both iOS & watchOS targets' Signing & Capabilities
3. Rebuild both targets

## Integration Points & Dependencies

### External Frameworks
- **SwiftUI, Combine:** Core UI & reactive state management
- **AVFoundation:** Audio playback (iOS & watchOS)
- **WatchConnectivity:** Phone ↔ watch messaging
- **WatchKit:** Haptics on watchOS; complication support

### Data Flow at Runtime

```
User starts timer (HomeView)
  → BipEngine.start(config)
  → Engine ticks every 0.5s
  → Phase complete → BipEngine.onBip callback
  → BipApp setup calls AudioHapticManager.playSound() + triggerHaptic()
  → Engine sends BipSessionState via WatchConnectivityManager.sendSessionState()
  → Watch receives and updates UI (WatchSessionView observes sessionState)
```

### Watch Complication

Requires `ComplicationController.swift`. Complication shows current phase label + time remaining. Updates tied to session state changes.

## Common Pitfalls & Edge Cases

1. **Missing App Group capability:** App won't share UserDefaults between targets. Both will have separate, empty configs.
2. **Sound files not bundled:** Check target membership in Xcode. Falls back to haptic-only if missing.
3. **Watch unreachable:** Engine keeps running on phone, but watch goes stale. Fallback to `applicationContext` helps, but real-time sync is lost.
4. **Repeat count = 0 loops forever:** By design. Ensure UI clarifies "0 = infinite."
5. **Simulator haptics:** Nearly non-functional. Always test on real iPhone + Watch.

## File Organization Quick Reference

| File | Purpose | Platform |
|------|---------|----------|
| `BipApp.swift`, `BipWatchApp.swift` | App entry; wires up dependency injection | iOS, watchOS |
| `Models.swift` | All data models, BipStore persistence | **Both targets** |
| `BipEngine.swift` | Timer ticker logic | **Both targets** |
| `WatchConnectivity.swift` | Phone ↔ watch messaging | **Both targets** |
| `AudioHapticManager.swift` | Platform-specific sound/haptic (conditional compile) | **Both targets** |
| `HomeView.swift`, `ConfigureView.swift`, `RunningView.swift`, `SettingsView.swift` | iOS UI | iOS only |
| `WatchSessionView.swift`, `WatchHistoryView.swift` | watchOS UI | watchOS only |
| `ComplicationController.swift` | Watch face complication | watchOS only |

## Key Constraints

- **iOS 18.0+, watchOS 11.0+** (device OS versions may lag; check README for actual tested versions)
- **Swift 5.9+** (Xcode 16+)
- **No background task scheduling yet** on iPhone (could use BGTaskScheduler for long-running sessions)
- **No persistent activity/live update on watch** beyond WatchConnectivity (WKExtendedRuntimeSession optional for extended background)

## Rapid Onboarding Checklist for New Features

- [ ] Does it involve timing logic? → Update `BipEngine.tick()`
- [ ] New data field? → Add to `BipTimerConfig` or `BipSessionState`, keep Codable, update sample configs
- [ ] New iOS UI? → Add View struct, inject dependencies via `@EnvironmentObject`
- [ ] New watch UI? → Same, but in `BipWatch Watch App/`
- [ ] New sound/haptic feedback? → Add to `AudioHapticManager`, add enum case to `BipHaptic`
- [ ] Needs to sync to watch? → Ensure state serialized in `BipSessionState`, wired in `WatchConnectivityManager`
- [ ] Test on device first (simulator haptics unreliable)


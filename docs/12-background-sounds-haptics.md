# 12 — Background Notification Sounds and Haptics

## Status
- [x] Implemented

## Complexity
**High**

## Problem
When the Bip app is in the background, phase-transition sounds and haptics are not triggered. The `BipEngine` timer stops ticking when iOS suspends the app, so `onBip` callbacks never fire.

## Root Cause
1. **No background execution mode** — the app has no `UIBackgroundModes` entitlement, so iOS suspends it within seconds of backgrounding.
2. **No background task registration** — `BipApp.swift` does not use `BGTaskScheduler` or `UIApplication.beginBackgroundTask`. A comment in `BipEngine.swift` (line 6) mentions these but they are not implemented.
3. **Audio session insufficient** — `AudioHapticManager` configures `.playback` with `.mixWithOthers`, but without the `audio` background mode the session is interrupted on suspend.
4. **Haptics are foreground-only** — `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator` are silently ignored when the app is not in the foreground. There is no workaround for this on iOS.

## Files to Touch
- `Bip/Bip.entitlements` — add background modes
- `Bip/Info.plist` or Xcode project settings — add `UIBackgroundModes`
- `Bip/BipApp.swift` — register background tasks or begin background task on timer start
- `Bip/BipEngine.swift` — integrate `UIApplication.beginBackgroundTask` around timer lifecycle
- `Bip/AudioHapticManager.swift` — ensure audio session stays active in background

## Implementation Approach

### Option A — `beginBackgroundTask` (simplest, limited)
Request extended background time when a timer starts. iOS grants ~30 seconds (up to ~3 minutes historically). Sufficient for short timers but not for 25-minute work sessions.

### Option B — Local Notifications (recommended)
Schedule `UNNotificationRequest` for each upcoming phase transition when the timer starts or a phase advances. Notifications fire with sound even when the app is suspended.
- Pre-calculate absolute `Date` for each remaining phase boundary
- Reschedule on skip/pause/resume
- Use custom notification sounds (copy .wav files to notification sound format)
- Haptics: not possible in background, but notification vibration serves as substitute

### Option C — Background Audio mode
Add `audio` to `UIBackgroundModes` and keep a silent audio loop playing to prevent suspension. This keeps the engine ticking and `onBip` firing normally. Apple may reject apps that misuse this mode, but timer apps with audible alerts have a legitimate case.

### Recommendation
**Option B** (local notifications) is the most robust and App Store-safe approach. Combine with Option A for a brief grace period after backgrounding where direct audio still works.

## Notes
- Haptics cannot fire in the background on iOS — notification vibration is the only substitute.
- watchOS is a separate concern; the watch engine and `WKExtendedRuntimeSession` are tracked separately.
- Notification sounds are limited to 30 seconds; phase-transition sounds are short so this is fine.
- Need to request notification permission (`UNUserNotificationCenter.requestAuthorization`).

## Verification
- Start a 1-minute timer with two 30s phases, background the app
- Confirm a sound/vibration fires at the 30s phase transition
- Confirm the notification appears in Notification Center
- Return to the app and confirm the timer state is correct

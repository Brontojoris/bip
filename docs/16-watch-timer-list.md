# 16 — Display Available Timers on BipWatch

## Status
- [ ] Implemented

## Complexity
**Medium**

## Problem
The watch app currently shows only "No timer running / Start a timer on iPhone" when idle. Users cannot browse or start timers from the watch — they must pick up their phone.

## Current Architecture
- Timer configs are stored in App Group UserDefaults (`group.com.jorisdebeer.Bip`) via `BipStore`
- The watch has access to the same App Group, so `BipStore` can load configs directly on the watch side
- The watch already has `BipEngine` available (injected in `BipWatchApp.swift`) but never starts it
- The watch can send a `commandStart` to the phone, but there is no mechanism to specify *which* config to start

## Files to Touch
- `BipWatch Watch App/WatchSessionView.swift` — replace `idleView` with a timer list
- `BipWatch Watch App/BipWatchApp.swift` — inject `BipStore` as environment object
- `BipWatch Watch App/WatchConnectivity.swift` — extend `sendCommand` to include config data for start command
- `Bip/BipApp.swift` — handle `commandStart` with config payload on phone side
- `Bip/WatchConnectivity.swift` — parse config data from start command

## Implementation Approach

### Phase 1 — Display the list
1. In `BipWatchApp`, create a `@StateObject private var store = BipStore()` and inject it into `WatchSessionView`.
2. Replace `idleView` with a `List` of `store.configs`, each showing the timer name and phase summary.
3. Style to fit watch screen (compact rows, caption fonts).

### Phase 2 — Start from watch
1. When a config row is tapped, send the config to the phone:
   - Encode `BipTimerConfig` as JSON data
   - Send via `WCSession.sendMessage` with key `WatchMessage.commandStart` and include `WatchMessage.configData`
2. On the phone side, in `BipApp.setupCallbacks()`, handle `commandStart` by decoding the config and calling `engine.start(config:)`.
3. Alternatively, start the engine locally on the watch using `engine.start(config:)` and sync state back to the phone.

### Recommendation
Send the start command with config data to the phone and let the phone be the source of truth for the running timer. The phone engine ticks and broadcasts state back to the watch. This avoids dual-engine sync issues.

## Notes
- `BipStore` reads from App Group UserDefaults, which is shared between phone and watch — configs created on the phone are already available on the watch without explicit sync.
- `WatchMessage.configData` and `WatchMessage.commandStart` constants already exist in `Models.swift`.
- If the phone is unreachable, the watch could start the engine locally as a fallback (but this is a stretch goal).

## Verification
- Open BipWatch with no timer running — see a list of saved timers
- Tap a timer — it starts on the phone and the watch shows the running view
- Create a new timer on the phone — it appears in the watch list (on next app launch or via UserDefaults sync)

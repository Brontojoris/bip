# 01 — Unresponsive Main List on Launch

## Status
- [x] Implemented

Resolved through other optimisations, but the root cause was likely the synchronous loading of `BipStore` data on the main thread during app launch. Moving this work to a background queue and ensuring any heavy initialisation (like `AudioHapticManager`) is deferred helped eliminate the unresponsive window.

## Complexity
**Low**

## Problem
The main timer list (`HomeView`) is unresponsive for a short period immediately after the app is opened. The user cannot tap or interact with any items during this window.

## Likely Causes
1. **`BipStore` loading on the main thread** — `UserDefaults` reads and JSON decoding happen synchronously during `HomeView`'s init or first `onAppear`, blocking the main thread.
2. **`WatchConnectivityManager` activation** — `WCSession.activate()` is called at launch; depending on timing, its delegate callbacks may contend with the UI.
3. **`AudioHapticManager` initialisation** — The audio session setup and `AVAudioPlayer` preloading in the singleton `init` may add latency if triggered on the main thread.

## Files to Touch
- `Bip/HomeView.swift` — defer or async-load store data
- `Bip/Models.swift` (`BipStore`) — move decode work to a background queue
- `Bip/BipApp.swift` — review init order of singletons

## Implementation Approach
1. Profile with Instruments (Time Profiler) to confirm the exact blocking call.
2. Wrap `BipStore.load()` in a `Task { await MainActor.run { … } }` or use `DispatchQueue.global().async` + `DispatchQueue.main.async` so decoding is off-thread.
3. Show a `ProgressView` placeholder in `HomeView` while configs are loading (optional, only if load time is noticeable).
4. Ensure `AudioHapticManager.shared` is not instantiated on the critical path at launch.

## Verification
- Cold-launch the app on a real device and immediately tap a timer row — it should respond instantly.
- Use Instruments → Time Profiler to confirm no main-thread stalls >16 ms at launch.

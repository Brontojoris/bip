# 13 — BipWatch Does Not Display Timer Until Rest Phase

## Status
- [ ] Implemented

## Complexity
**Medium**

## Problem
When a timer is started on the iPhone, the Apple Watch does not show the running timer UI until the first phase transition (e.g., the Rest phase begins). The watch stays on the "No timer running" idle screen during the entire first phase.

## Root Cause (likely)
The watch UI reads `connectivity.sessionState.isRunning` to decide whether to show `runningView` or `idleView` (`WatchSessionView.swift:12`). The phone sends state via `WatchConnectivityManager.sendSessionState()`, but this is only called inside the `engine.onBip` callback (`BipApp.swift`), which fires on **phase transitions** — not on timer start.

So the first state update the watch receives is when the first phase completes, which is why it only appears at the Rest phase.

## Files to Touch
- `Bip/BipApp.swift` — send initial state to watch when timer starts
- `Bip/BipEngine.swift` — possibly add an `onStart` callback, or send state on every tick

## Implementation Approach

### Option A — Send state on start (minimal)
In `BipApp.setupCallbacks()`, add an `engine.onStart` callback (or post-start hook) that calls `connectivity.sendSessionState(engine.state)` immediately after `engine.start()` is called.

### Option B — Send state on every tick (comprehensive)
Have the engine call a new `onTick` callback each tick interval (0.5s). Wire this in `BipApp` to `connectivity.sendSessionState()`. This keeps the watch countdown live and in sync. Throttle to every 1–2 seconds to avoid flooding WCSession.

### Recommendation
**Option B** — sending state periodically solves both the "no display on start" bug and the "watch timer doesn't count down" issue (see doc 15). Throttle to every ~1 second to balance responsiveness with WCSession throughput.

## Notes
- The `startTimer()` function in `HomeView.swift:72-78` calls `engine.start(config:)` directly. State could also be sent there, but wiring it in `BipApp` via a callback is cleaner.
- The watch also receives state via `applicationContext` fallback, but this only delivers when the watch app wakes — not useful for live display.

## Verification
- Start a timer on iPhone
- Watch should immediately show the running view with phase label and countdown
- No delay until first phase transition

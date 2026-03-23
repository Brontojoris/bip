# 15 — BipWatch Timer Doesn't Count Down

## Status
- [x] Implemented

## Complexity
**Medium**

## Problem
The watch displays a static time value that does not count down in real time. The displayed time only updates when the phone sends a new `BipSessionState` snapshot, which currently only happens on phase transitions (via the `onBip` callback).

## Root Cause
The watch UI reads `connectivity.sessionState.timeRemaining` (`WatchSessionView.swift:28`), which is a computed property on the last-received `BipSessionState` snapshot. The phone only sends state updates in `engine.onBip` (`BipApp.swift`), so between phase transitions the watch shows a frozen countdown.

The watch has its own `BipEngine` instance (`BipWatchApp.swift:7`) but it is never started or fed data — it sits idle.

## Files to Touch
- `Bip/BipApp.swift` — send state to watch periodically (not just on bip)
- `Bip/BipEngine.swift` — add `onTick` callback or periodic state broadcast

## Implementation Approach

### Option A — Periodic state broadcast from phone (recommended)
Add an `onTick` callback to `BipEngine` that fires every tick (0.5s). In `BipApp.setupCallbacks()`, wire this to send state to the watch. Throttle to every ~1 second to avoid WCSession congestion.

```swift
// In BipEngine.tick()
onTick?(state)

// In BipApp.setupCallbacks()
var lastWatchSync: Date = .distantPast
engine.onTick = { [connectivity] state in
    let now = Date()
    if now.timeIntervalSince(lastWatchSync) >= 1.0 {
        connectivity.sendSessionState(state)
        lastWatchSync = now
    }
}
```

### Option B — Watch-side local countdown
Instead of receiving frequent updates, the watch could use the last-received snapshot's `startedAt`, `currentPhaseElapsed`, and `currentPhaseDuration` to compute a local countdown using a `TimelineView` or local `Timer`. This reduces WCSession traffic but adds complexity for pause/skip sync.

### Recommendation
**Option A** — periodic broadcast is simpler and keeps the watch perfectly in sync with the phone. This also fixes doc 13 (no display until Rest phase) as a side effect.

## Relationship to Other Items
- **Doc 13** (watch doesn't display until Rest): same root cause — fixed together by periodic state broadcast.
- If implementing both, a single `onTick` callback with throttled `sendSessionState` resolves both issues.

## Verification
- Start a timer on iPhone
- Watch countdown should decrement every ~1 second
- Skip a phase on iPhone — watch updates within 1 second
- Pause/resume on iPhone — watch reflects the change promptly

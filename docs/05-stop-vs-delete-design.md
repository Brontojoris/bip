# 05 — Stop vs Delete Design Decision

## Status
- [x] Decision made — Option B chosen
- [x] Implemented

## Complexity
**Low** (design decision) / **Medium** (if state machine changes are required)

## Problem
Currently, stopping a timer also deletes it — the session ends and the user is returned to `HomeView` with no trace of what they were running. The question is: should "stop" mean "end & delete" or "end & keep"?

## Options

### Option A — Keep current behaviour (stop = delete) with better feedback
- No state machine changes needed.
- Pair with item 04 (confirmation dialog) so the user understands the action is destructive.
- **Pro:** Simple, no new state to manage.
- **Con:** User loses their timer if they accidentally stop it; they must recreate it.

### Option B — Stop = end session, keep config (recommended)
- Stopping ends the active `BipSessionState` but does not remove the `BipTimerConfig` from `BipStore`.
- The config remains in `HomeView`'s list and can be restarted.
- This is likely the expected behaviour — "stop" means stop the *run*, not delete the *recipe*.
- **Pro:** Non-destructive, matches user expectations from other timer apps.
- **Con:** Tiny amount of engine/state work; need to ensure `BipEngine` and `WatchConnectivityManager` correctly clear the session without clearing the config.

### Option C — Introduce explicit "Delete" separate from "Stop"
- Stop ends the session (like Option B).
- A separate "Delete" action (swipe, long-press, or edit mode) removes the config.
- **Pro:** Maximum clarity.
- **Con:** More UI surface to implement; may feel over-engineered for a simple timer app.

## Recommendation
**Option B.** Stop should end the current run and return to `HomeView`, leaving the config intact. A separate swipe-to-delete (already partially implemented) handles removal. This aligns with how most timer/interval apps behave.

## Files That Would Change (Option B)
- `Bip/BipEngine.swift` — `stop()` resets session state but does not remove the config
- `Bip/HomeView.swift` — ensure `RunningRowView` disappears when session ends (already driven by `engine.isRunning`)
- `Bip/RunningView.swift` — stop button dismisses view; no delete call
- `Bip/Models.swift` — no changes needed; `BipStore` and `BipTimerConfig` are already separate from `BipSessionState`

## Notes
- This decision gates items 03, 04, and 10 — implement this first.
- Items 03 and 10 both need to know what "stop" does before adding stop buttons.

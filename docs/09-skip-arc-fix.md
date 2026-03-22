# 09 — Fix Progress Arc on Skip

## Status
- [ ] Implemented

## Complexity
**Medium**

## Problem
When the user taps "Skip" in `RunningView`, the circular progress arc jumps abruptly to the start of the next phase. The arc should instead animate to completion (full circle, `progress = 1.0`) before snapping to the new phase, giving the user a clear visual signal that the current phase was skipped/completed.

## Files to Touch
- `Bip/RunningView.swift` — Skip button action and the progress ring animation

## Current Behaviour
The Skip button likely calls something like `engine.skipToNextPhase()` immediately, which resets `BipSessionState.currentPhaseIndex` and `elapsed`. The `progress` computed property on `BipSessionState` then jumps from mid-value directly to ~0.0 for the new phase. The `Circle` trim animates between these two values, causing the arc to visually shrink rather than complete.

## Implementation Approach

### Step 1 — Introduce a `isSkipping` local state flag
```swift
@State private var isSkipping = false
```

### Step 2 — Animate to full circle before advancing
```swift
Button("Skip") {
    guard !isSkipping else { return }
    isSkipping = true
    withAnimation(.easeOut(duration: 0.25)) {
        // Temporarily override displayed progress to 1.0
        displayProgress = 1.0
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        engine.skipToNextPhase()
        isSkipping = false
    }
}
```

### Step 3 — Decouple display progress from engine progress
The progress ring currently reads `engine.sessionState.progress` directly. Introduce a local `@State var displayProgress: Double` that normally mirrors the engine value but is overridden during the skip animation.

```swift
// In the progress ring view:
Circle()
    .trim(from: 0, to: isSkipping ? 1.0 : engine.sessionState.progress)
    .animation(.linear(duration: 0.5), value: engine.sessionState.progress)
```

Or more cleanly, compute a single `ringProgress` variable that returns `1.0` while `isSkipping`, and `engine.sessionState.progress` otherwise.

## Notes
- Keep the animation duration short (~0.2–0.3 s) so skipping still feels instant.
- Ensure the Skip button is disabled (`isSkipping`) during the animation to prevent double-taps.
- The watch side does not have a skip button, so no watch changes are needed.
- `BipEngine.skipToNextPhase()` (or equivalent) should be called *after* the animation completes, not before.

## Verification
- Tap Skip mid-phase → arc smoothly completes the full circle, then the next phase begins from 0.
- Tapping Skip rapidly (double-tap) does not cause the arc to glitch or the engine to skip two phases.
- The normal phase-end transition (timer reaches 0) still draws the full arc naturally.

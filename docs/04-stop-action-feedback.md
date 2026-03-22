# 04 — Clearer Stop Feedback in RunningView

## Status
- [ ] Implemented

## Complexity
**Low**

## Problem
When the user taps the stop button in `RunningView`, the timer stops and is deleted silently — there is no visual confirmation and no clear indication of what just happened. The app returns to `HomeView` without acknowledging the action.

## Files to Touch
- `Bip/RunningView.swift`

## Implementation Approach

### Option A — Confirmation dialog (recommended for destructive action)
Use `.confirmationDialog` to ask the user before stopping, especially if stop = delete (see item 05).

```swift
.confirmationDialog("Stop timer?", isPresented: $showStopConfirm, titleVisibility: .visible) {
    Button("Stop & Delete", role: .destructive) {
        engine.stop()
        dismiss()
    }
    Button("Cancel", role: .cancel) {}
}
```

### Option B — Brief "Stopped" overlay before dismissing
Show a full-screen or banner overlay for ~0.8 s before dismissing back to `HomeView`.

```swift
// After stop():
withAnimation { showStoppedOverlay = true }
DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
    dismiss()
}
```

### Recommendation
Use **Option A** (confirmation dialog) if stop = delete (item 05 decision). If stop merely pauses, use **Option B** (animated feedback) so the flow feels lighter.

## Notes
- Dependent on item 05 (stop vs delete design decision).
- The confirmation dialog wording should clearly state whether the timer will be deleted or just paused.

## Verification
- Tap stop in `RunningView` → confirmation appears (Option A) or overlay flashes (Option B).
- User is returned to `HomeView` after confirming.
- No timer remains active after the stop action completes.

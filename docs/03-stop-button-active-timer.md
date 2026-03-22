# 03 — Stop Button on Active Timer in Home List

## Status
- [ ] Implemented

## Complexity
**Low**

## Problem
When a timer is running, `HomeView` shows a `RunningRowView` at the top of the list. There is no way to stop the timer from this row; the user must navigate into `RunningView` to find the stop button.

## Files to Touch
- `Bip/HomeView.swift` — `RunningRowView`

## Implementation Approach
Add a square stop `Button` at the trailing edge of `RunningRowView`.

```swift
// Inside RunningRowView's HStack
Button {
    engine.stop()
} label: {
    Image(systemName: "stop.fill")
        .foregroundStyle(.red)
        .font(.title2)
}
.buttonStyle(.plain)
```

- The button calls `engine.stop()` (or whatever the existing stop mechanism is in `HomeView`).
- Use `.buttonStyle(.plain)` so the tap target is isolated from the row's navigation tap.
- Consider pairing with item 04 (feedback on stop) and item 05 (stop vs delete design decision) — the exact behaviour on tap (delete vs pause) should be resolved first.

## Notes
- This is closely related to items 04 and 05. Implement after the stop/delete design decision (05) is made.
- The stop icon (`stop.fill`) matches the existing stop button in `RunningView` for consistency.

## Verification
- While a timer is running, tap the stop button in the `RunningRowView` → timer stops.
- The row disappears (or updates) appropriately based on the stop/delete decision.
- Navigating into `RunningView` while the timer is running still works normally.

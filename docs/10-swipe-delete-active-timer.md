# 10 — Swipe to Delete Active Timer

## Status
- [ ] Implemented

## Complexity
**Low**

## Problem
The user cannot swipe to delete/stop the currently running timer from `HomeView`. The `RunningRowView` at the top of the list has no swipe actions, meaning the only way to stop the timer is to navigate into `RunningView`.

## Files to Touch
- `Bip/HomeView.swift` — `RunningRowView`

## Dependencies
- **Item 05** (stop vs delete design decision) — must know what "stopping" means before wiring the swipe action.

## Implementation Approach
Add a `.swipeActions(edge: .trailing)` to `RunningRowView` with a destructive stop/delete button.

```swift
RunningRowView(engine: engine)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
        Button(role: .destructive) {
            engine.stop()
        } label: {
            Label("Stop", systemImage: "stop.fill")
        }
    }
```

- `role: .destructive` applies the red background automatically.
- `allowsFullSwipe: true` lets users full-swipe to stop, consistent with the existing delete behaviour on normal rows.
- Pair with item 04 feedback if a confirmation dialog is desired — though for a swipe action, a confirmation dialog may feel redundant (the swipe gesture itself is intentional).

## Notes
- If the decision from item 05 is that stop ≠ delete (i.e., the config is retained), the label should read "Stop" with a `stop.fill` icon, not "Delete".
- If stop = delete, use a trash icon and `"Delete"` label.
- This is closely related to item 03 (stop button on the row) — consider implementing both together to reduce the number of `HomeView` touch points.

## Verification
- While a timer is running, swipe left on `RunningRowView` → destructive stop action appears.
- Tapping (or full-swiping) the action stops the timer and removes the running row.
- Normal timer rows still have their existing swipe-to-delete action.

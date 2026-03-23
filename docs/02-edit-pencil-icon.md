# 02 — Edit/Pencil Icon on List Items

## Status
- [x] Implemented

## Complexity
**Low**

## Problem
There is no visible edit affordance on timer rows in `HomeView`. Users must know to swipe left to access the edit action, which is not discoverable.

## Files to Touch
- `Bip/HomeView.swift` — `TimerRowView` and/or the `List` row content

## Implementation Approach

### Option A — Trailing icon in the row (recommended)
Add a pencil `Button` at the trailing edge of `TimerRowView`. Tapping it opens `ConfigureView` in a sheet or navigation push.

```swift
// Inside TimerRowView (or the row's HStack in HomeView)
Spacer()
Button {
    // set selectedConfig = config, show sheet
} label: {
    Image(systemName: "pencil")
        .foregroundStyle(.secondary)
}
.buttonStyle(.plain) // prevents the whole row activating on tap
```

### Option B — Add to existing swipe actions
Extend the existing `.swipeActions(edge: .leading)` with an edit action (pencil, `.tint(.blue)`). Less discoverable than Option A but keeps the row visually clean.

### Recommendation
Use **Option A** — a persistent icon is immediately visible and reduces the need for gesture discovery.

## Notes
- The `ConfigureView` sheet is already used when tapping the "+" button; reuse the same sheet/navigation presentation.
- Use `.buttonStyle(.plain)` on the pencil button so the tap target is tight and doesn't conflict with the row's own `NavigationLink` or tap gesture.

## Verification
- Tap the pencil icon on a row → `ConfigureView` opens pre-populated with that timer's settings.
- Editing and saving updates the row in the list.
- Existing swipe-to-delete still works.

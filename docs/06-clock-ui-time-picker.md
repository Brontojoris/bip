# 06 — Visual Clock UI for Phase Duration Picker

## Status
- [ ] Implemented

## Complexity
**High**

## Problem
Phase durations are currently set with a linear slider (`0.5–120 min`) in `ConfigureView` → `PhaseRowView`. This is functional but not particularly intuitive or tactile for a timer app. A visual clock face would be more engaging and easier to use for common durations.

## Files to Touch
- `Bip/ConfigureView.swift` — replace `PhaseRowView` slider with the new picker
- `Bip/ClockPickerView.swift` *(new file)* — custom clock component

## Design

### What it should look like
An analogue clock face where the user drags a single hand to set a duration from **0 seconds up to 60 minutes** (or up to 120 min with two rotations). The hand snaps to configurable increments (e.g., 5 s, 10 s, 1 min).

### Sub-components needed
1. **`ClockFaceView`** — `Canvas`/`Path`-based clock face with tick marks and labels.
2. **Drag gesture** — `DragGesture` converting touch position to angle, then angle to duration.
3. **Snap logic** — round the raw angle to the nearest step increment.
4. **Range support** — handle both short durations (seconds, from item 07) and long durations (minutes).

### Key geometry
```
angle = atan2(touchPoint.x - center.x, -(touchPoint.y - center.y))
// Normalise to 0…2π, then map to 0…maxDuration
```

## Implementation Steps
1. Create `ClockPickerView` as a standalone SwiftUI view accepting `Binding<TimeInterval>`, `minDuration`, `maxDuration`, and `step`.
2. Draw the clock face with `Canvas`: outer ring, tick marks (major at 5-min/15-s intervals, minor between), current hand.
3. Add `DragGesture(minimumDistance: 0)` on the clock face to update the binding.
4. Animate the hand with `.animation(.interactiveSpring(), value: duration)`.
5. Replace the `Slider` in `PhaseRowView` (`ConfigureView.swift`) with `ClockPickerView`.
6. Display the selected time numerically below the clock face for precision.

## Notes
- Implement item 07 (shorter times) first, as it defines the minimum duration the picker must support.
- Accessibility: add `.accessibilityValue` with the formatted duration string; support VoiceOver scrubbing as a fallback.
- Consider a two-mode UI: a simple "minutes" mode for durations ≥1 min, and a "seconds" mode for shorter intervals, toggled by a segmented control.
- Watch app (`BipWatch Watch App/`) does not have a config UI, so no watch-side changes needed.

## Verification
- Open `ConfigureView`, edit a phase → clock picker is shown.
- Drag the hand to various positions → duration label updates in real time.
- Save the config → phases retain the correct durations.
- Very short durations (e.g., 10 s) and long durations (e.g., 90 min) are both reachable.

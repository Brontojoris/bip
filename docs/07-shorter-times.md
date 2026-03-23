# 07 — Allow Phase Durations Shorter Than 30 Seconds

## Status
- [x] Implemented

## Complexity
**Low**

## Problem
The phase duration slider in `ConfigureView` → `PhaseRowView` has a minimum of `0.5` (interpreted as 0.5 minutes = 30 seconds). Users cannot create phases shorter than 30 seconds, which limits use cases like high-intensity intervals, quick drills, or short beep sequences.

## Files to Touch
- `Bip/ConfigureView.swift` — `PhaseRowView` slider `range` and `step` parameters
- `Bip/ConfigureView.swift` — duration display formatting (may assume minutes)

## Current Behaviour (to confirm)
In `PhaseRowView`, the slider likely uses something like:
```swift
Slider(value: $phase.duration, in: 0.5...120, step: 0.5)
```
where `duration` is stored in **minutes**, making 0.5 min the minimum.

## Implementation Approach
1. **Change the unit** — store duration in **seconds** (or confirm it already is in `BipPhase.duration: TimeInterval`). If currently in minutes, migrate stored values.
2. **Update the slider range** — change to a sensible minimum, e.g. `5...7200` seconds (5 s to 2 hours) or use a two-range approach (seconds vs minutes).
3. **Update display formatting** — format short durations as `"0:05"` (mm:ss) and longer ones as `"2 min 30 s"` or `"2:30"`.

### Suggested slider range
```swift
// Seconds-based
Slider(value: $phase.duration, in: 5...7200, step: 5)
```
Or split into two sliders/pickers: one for minutes (0–120) and one for seconds (0–55 in steps of 5), combined into a total.

## Notes
- `BipEngine` ticks every 0.5 s, so any duration that is a multiple of 0.5 s will work precisely.
- The minimum practical duration is probably 5 s — short enough for most use cases without being error-prone.
- Implement this **before** item 06 (clock UI), since the clock picker must know the supported range.
- Check `BipWatch Watch App/` — the watch engine uses the same duration values, so no watch-specific changes are needed as long as the model stays consistent.

## Verification
- Create a phase with a 10-second duration → it saves correctly.
- The timer runs the phase for exactly 10 seconds before advancing.
- Duration is displayed correctly in both `ConfigureView` and the phase sequence label in `HomeView`/`RunningView`.

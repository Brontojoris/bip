# 08 — Improve Haptics

## Status
- [ ] Implemented

## Complexity
**Medium**

## Problem
The current haptic feedback is basic — a single tap from one of the `BipHaptic` enum cases. For a timer app used during exercise or cooking, the feedback needs to be more distinctive and noticeable so users can feel phase transitions without looking at the screen.

## Files to Touch
- `Bip/AudioHapticManager.swift` — add new pattern implementations (iOS)
- `BipWatch Watch App/AudioHapticManager.swift` — add watch-side patterns
- `Bip/Models.swift` (`BipHaptic` enum) — add new pattern cases
- `Bip/ConfigureView.swift` — update haptic picker to show new options

## Current State
`BipHaptic` enum: `notification`, `start`, `stop`, `success`, `retry`, `click`
These map directly to `UINotificationFeedbackGenerator` or `UIImpactFeedbackGenerator` — single taps only.

## Implementation Approach

### Step 1 — Add multi-pulse patterns
Use `DispatchQueue.main.asyncAfter` to fire multiple haptic calls in sequence.

```swift
// Example: double-tap pattern
func doubleTap() {
    impact.impactOccurred(intensity: 1.0)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
        self.impact.impactOccurred(intensity: 0.8)
    }
}

// Example: triple-tap (strong alarm)
func tripleTap() {
    for i in 0..<3 {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
            self.impact.impactOccurred(intensity: 1.0)
        }
    }
}
```

### Step 2 — New `BipHaptic` cases
```swift
enum BipHaptic: String, Codable, CaseIterable {
    // existing
    case notification, start, stop, success, retry, click
    // new
    case doubleTap      // two quick pulses
    case tripleTap      // three quick pulses (strong alarm)
    case longBuzz       // heavy impact held via rapid repeats
}
```

### Step 3 — Watch-side parity
The watch has a richer `WKHapticType` set. Map the new patterns to the best available watch haptic type:
- `doubleTap` → `.directionUp` (or `.start` twice)
- `tripleTap` → `.notification`
- `longBuzz` → `.retry`

### Step 4 — Update ConfigureView haptic preview
The haptic picker in `ConfigureView` already fires a preview tap on selection — ensure new patterns are previewed correctly.

## Notes
- Use `UIImpactFeedbackGenerator(style: .heavy)` for maximum intensity on iOS.
- Call `.prepare()` before each burst to reduce latency.
- Test on a physical device — simulator haptics are unreliable.
- Do not use `CoreHaptics` (`CHHapticEngine`) unless needed; the simple generator API is sufficient and avoids engine startup latency.

## Verification
- Open `ConfigureView`, select each new haptic type → feel the pattern immediately in preview.
- Run a timer to a phase transition → the selected haptic fires with the correct pattern.
- Test on Apple Watch — watch-side haptics fire on phase transitions.

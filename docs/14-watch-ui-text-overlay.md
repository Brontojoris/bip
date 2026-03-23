# 14 — BipWatch UI: Red Heading Overlays Phase Label

## Status
- [x] Implemented

## Complexity
**Low**

## Problem
On the BipWatch running view, the red navigation title (e.g., "Quick Intervals") overlaps or is overlaid on top of the phase label text (e.g., "Rest"). This makes the phase label unreadable.

## Root Cause (likely)
`WatchSessionView.swift:66` sets `.navigationTitle(state.configName)` with `.navigationBarTitleDisplayMode(.inline)`. On small watch screens, the inline navigation title can overlap the first content element in the `VStack` — which is `state.currentPhaseLabel` at line 23.

The `VStack(spacing: 4)` at line 22 starts immediately below the navigation bar, and with `.inline` display mode, the title bar may be too close or overlap the phase label depending on watch size and content height.

## Files to Touch
- `BipWatch Watch App/WatchSessionView.swift` — adjust layout of `runningView`

## Implementation Approach

1. **Add top padding** to the VStack to create space below the navigation title:
   ```swift
   .padding(.top, 8)
   ```

2. **Or remove the navigation title** from the running view entirely and show the config name as a styled `Text` element within the VStack, giving full control over positioning.

3. **Or use `.toolbar` content** instead of `.navigationTitle` for more layout control on watchOS.

### Recommendation
Option 2 — replace `.navigationTitle(state.configName)` with a `Text(state.configName)` at the top of the VStack, styled as a caption. This avoids navigation bar layout quirks on small watch screens and gives consistent results across watch sizes.

## Verification
- Start a timer with a long config name (e.g., "Quick Intervals")
- Check watch display: config name and phase label should both be fully readable with no overlap
- Test on smallest supported watch size (41mm)

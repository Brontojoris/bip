# 17 — Modernise Watch Complication with WidgetKit

## Status
- [ ] Implemented

## Complexity
**High**

## Problem
The existing `ComplicationController.swift` uses the legacy ClockKit API (`CLKComplicationDataSource`), which has been deprecated since watchOS 9. Additionally, the complication reads `currentSessionState` from UserDefaults, but nothing in the app ever writes that key — so the complication always shows placeholder text ("Bip" / "--:--").

The project targets watchOS 11.6+, so ClockKit should be replaced entirely with WidgetKit.

## Goals
1. Replace the ClockKit complication with a WidgetKit-based widget extension.
2. Show live countdown during an active timer (phase label + time remaining).
3. Show an idle/branded state when no timer is running.
4. Support the most useful complication families for watchOS.

## Files to Touch
- **Delete:** `BipWatch Watch App/ComplicationController.swift`
- **Create:** New widget extension target (e.g., `BipWatchWidget/`)
  - `BipWatchWidget.swift` — `@main` Widget entry point
  - `BipWidgetTimelineProvider.swift` — `TimelineProvider` conformance
  - `BipWidgetEntryView.swift` — SwiftUI view for each complication family
- **Modify:** `Bip/BipApp.swift` or `BipWatch Watch App/WatchConnectivity.swift` — write state to shared UserDefaults so the widget extension can read it
- **Modify:** `Bip.xcodeproj` — add the widget extension target, shared App Group capability

## Architecture

### Widget Extension Target
WidgetKit complications run in a **separate process** from the watch app. They cannot directly access `@StateObject` or `WatchConnectivityManager`. Data must be shared via:
- **App Group UserDefaults** (`group.com.jorisdebeer.Bip`) — already configured
- **WidgetCenter.shared.reloadTimelines()** — called from the watch app whenever state changes

### Data Flow
```
Phone engine ticks → sends state via WCSession → Watch app receives state
  → Writes to App Group UserDefaults (key: "widgetSessionState")
  → Calls WidgetCenter.shared.reloadTimelines("BipWidget")
  → Widget extension reads from UserDefaults → renders timeline
```

### Timeline Strategy
- **When idle:** Single static entry showing "Bip" branding / "No timer" with `.never` refresh policy.
- **When running:** Use `Text(.date, style: .timer)` with a computed target date for system-driven countdown rendering. This lets watchOS animate the countdown natively without needing frequent timeline reloads.
  - Compute target date as: `Date().addingTimeInterval(state.timeRemaining)`
  - Schedule a timeline reload at the phase end time so the complication updates when the phase transitions.
- **On phase transition:** Watch app calls `WidgetCenter.shared.reloadTimelines()` to refresh with the new phase label and duration.

### Supported Families (watchOS 10+)
| Family | What to Show |
|--------|-------------|
| `.accessoryInline` | "Work 2:34" — phase label + countdown |
| `.accessoryCircular` | Circular gauge with countdown text |
| `.accessoryRectangular` | Phase label, countdown, cycle count |
| `.accessoryCorner` | Countdown text with gauge arc |

Drop legacy families (`.modularSmall`, `.utilitarianLarge`, etc.) — they're unavailable on modern watch faces.

## Implementation Steps

### Step 1 — Write state to shared UserDefaults
In the watch app's `WatchConnectivity.swift`, when `sessionState` is updated, also persist it:
```swift
func updateSessionState(_ state: BipSessionState) {
    self.sessionState = state
    // Persist for widget extension
    if let data = try? JSONEncoder().encode(state) {
        UserDefaults(suiteName: APP_GROUP_ID)?.set(data, forKey: "widgetSessionState")
    }
    WidgetCenter.shared.reloadTimelines(ofKind: "BipWidget")
}
```

### Step 2 — Create widget extension target
In Xcode: File → New → Target → Widget Extension (watchOS). Name: `BipWatchWidget`. Enable App Group capability with `group.com.jorisdebeer.Bip`.

### Step 3 — Implement TimelineProvider
```swift
struct BipWidgetEntry: TimelineEntry {
    let date: Date
    let phaseLabel: String
    let timeRemaining: TimeInterval
    let isRunning: Bool
    let progress: Double
}

struct BipWidgetProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<BipWidgetEntry>) -> Void) {
        let state = loadState()
        let entry = BipWidgetEntry(
            date: .now,
            phaseLabel: state?.currentPhaseLabel ?? "Bip",
            timeRemaining: state?.timeRemaining ?? 0,
            isRunning: state?.isRunning ?? false,
            progress: state?.progress ?? 0
        )
        // Reload at phase end, or in 15 min if idle
        let refreshDate: Date
        if let state, state.isRunning {
            refreshDate = Date().addingTimeInterval(state.timeRemaining)
        } else {
            refreshDate = Date().addingTimeInterval(15 * 60)
        }
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}
```

### Step 4 — Build entry views per family
Use `Text(.init(timeInterval:), style: .timer)` for the live countdown — this is rendered natively by the system and doesn't require timeline reloads to animate.

### Step 5 — Delete legacy ComplicationController.swift
Remove from the watch target and clean up any ClockKit references in `Info.plist`.

## Xcode Configuration Notes
- The widget extension needs its own **bundle identifier** (e.g., `com.jorisdebeer.Bip.watchkitapp.widget`)
- Add the same **App Group** capability (`group.com.jorisdebeer.Bip`) to the widget extension target
- Shared model files (`BipSessionState`, `APP_GROUP_ID`) need target membership in the widget extension, or use a shared framework

## Risks & Considerations
- **Widget budget:** watchOS limits how often widgets can reload. Using `Text(.date, style: .timer)` avoids this by letting the system animate the countdown.
- **Stale data:** If the phone disconnects mid-timer, the widget shows the last-known state. The timeline refresh at phase-end will show stale data. Mitigation: include `startedAt` timestamp and compute staleness in the view.
- **Shared models:** The widget extension is a separate target. Model files (`BipSessionState`, `BipPhase`, etc.) need to be compiled into it — either via target membership or a shared Swift package.

## Verification
- [ ] Add "Bip" complication to a watch face
- [ ] Start a timer on iPhone → complication shows phase label and live countdown
- [ ] Phase transitions update the complication within a few seconds
- [ ] Stop timer → complication returns to idle state
- [ ] Complication still shows correctly after watch app is killed (reads from UserDefaults)

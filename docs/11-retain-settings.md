# 11 — Retain Timer Settings Across App Installs/Upgrades

## Status
- [ ] Implemented

## Complexity
**Medium**

## Problem
Timer configurations are stored in App Group `UserDefaults` (`group.com.jorisdebeer.Bip`). While these persist across app *updates*, they are wiped when the app is *uninstalled*. Users lose all their custom timers if they reinstall the app (e.g., after a device restore, a new device, or accidentally deleting the app).

## Files to Touch
- `Bip/Models.swift` (`BipStore`) — add iCloud KV sync layer
- `Bip/BipApp.swift` — subscribe to iCloud change notifications
- `Bip.xcodeproj` — enable iCloud capability (Key-Value Storage)

## Options

### Option A — Export/Import JSON (no iCloud)
- Add an "Export" button in Settings that writes configs to a JSON file the user can save via `ShareSheet`.
- Add "Import" to load from a file.
- **Pro:** No entitlement needed, works offline.
- **Con:** Manual process; user must remember to export before uninstalling.

### Option B — iCloud Key-Value Store (recommended)
Use `NSUbiquitousKeyValueStore` to automatically back up and restore configs.

```swift
// Save
let data = try JSONEncoder().encode(configs)
NSUbiquitousKeyValueStore.default.set(data, forKey: "bipConfigs")
NSUbiquitousKeyValueStore.default.synchronize()

// Load (with UserDefaults fallback)
if let data = NSUbiquitousKeyValueStore.default.data(forKey: "bipConfigs") {
    configs = try JSONDecoder().decode([BipTimerConfig].self, from: data)
}
```

Subscribe to `NSUbiquitousKeyValueStore.didChangeExternallyNotification` to pick up changes from other devices.

**Limits:** 1 MB total, 1024 keys max — well within range for timer configs.

**Pro:** Automatic, cross-device, survives reinstalls. No CloudKit complexity.
**Con:** Requires iCloud capability entitlement; user must be signed into iCloud.

### Option C — CloudKit
Full CloudKit sync with conflict resolution.
- **Pro:** Unlimited storage, fine-grained sync.
- **Con:** Significantly more complex; overkill for simple config data.

## Recommendation
**Option B** (iCloud KV Store). It is the simplest solution that survives reinstalls and syncs across devices.

## Implementation Steps
1. In Xcode, enable the **iCloud** capability for the iOS target, check **Key-value storage**.
2. Update `BipStore.save()` to also write to `NSUbiquitousKeyValueStore`.
3. Update `BipStore.load()` to check iCloud KV first, then fall back to `UserDefaults` (for existing installs).
4. In `BipApp.swift`, subscribe to `NSUbiquitousKeyValueStore.didChangeExternallyNotification` and reload `BipStore` when fired.
5. Handle the first-launch merge: if both local `UserDefaults` and iCloud KV have data, prefer iCloud (it may be more up-to-date from a previous install).

## Notes
- The watch app reads configs sent over WCSession, not directly from `UserDefaults` or iCloud, so no watch-side changes are needed for the persistence layer.
- Ensure `BipTimerConfig` remains `Codable`-compatible; the existing custom `Codable` implementation in `Models.swift` already handles backward compatibility.
- For Option B, test the scenario where iCloud is unavailable (airplane mode) — the app should fall back to local `UserDefaults` gracefully.

## Verification
- Install app, create custom timers.
- Delete and reinstall the app.
- On relaunch, all timers are restored automatically (Option B) or via import (Option A).
- Timers also appear on a second device signed into the same Apple ID (Option B).

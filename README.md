# Bip — Setup Guide

## Requirements
- Xcode 16+
- iOS deployment target: 18.0
- watchOS deployment target: 11.0
- Tested on iPhone 13 Mini + Apple Watch Series 8

## Project Setup

1. Open Xcode → File → New → Project
2. Choose **iOS → App** template, name it **Bip**
3. Add a **watchOS App** target: File → New → Target → Watch App for iOS App
   - Name: BipWatch
   - Ensure "Include Notification Scene" is OFF
4. Add an **App Group** capability to both targets:
   - Signing & Capabilities → + Capability → App Groups
   - Group ID: group.com.yourname.bip  (replace with your bundle prefix)
   - Update the APP_GROUP_ID constant in Models.swift accordingly
5. Copy source files from this ZIP into your project:
   - Shared/*.swift → add to BOTH targets (iOS + watchOS)
   - iOS/*.swift → iOS target only
   - watchOS/*.swift → watchOS target only
6. In your watchOS target, enable **Background Modes**: Workout Processing
7. Build & run on device (simulator haptics are limited)

## Sound Files
Bip ships with 3 bundled tones. Add these short audio files (.wav or .caf)
to your iOS target's bundle:
  - bip-soft.wav   (gentle sine blip, ~80ms)
  - bip-bell.wav   (small bell, ~200ms)
  - bip-click.wav  (mechanical click, ~60ms)

You can source free short tones from freesound.org or record your own.
The app will fall back to UINotificationFeedbackGenerator if sounds are missing.

## App Group ID
Search for APP_GROUP_ID in Models.swift and replace with your actual group ID.

## Watch Complication
After installing on device, long-press your watch face → Edit → Complications,
then select Bip from the list. The complication shows current phase + time remaining.

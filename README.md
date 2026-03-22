# Bip
"Bip" is a timer app, with 2 states, a configurable "Work time", and a configurable "Rest" time. At each interval, the app will make a soft/configurable "bip" trigger a haptic.

Some use cases to explain how I would use this app.

## Scenario 1

I am the team manager for my child's Hockey team. Just before the game starts, I configure "bip" with an "Work" time of 25 minutes, (representing the first half of the game), then a "Rest" time of 5 minutes. When the game begins, I press start. After 25 minutes, I hear and feel a "bip", and I know it's the end of the first half of the game. I don't have to interact with my phone or watch at all. 5 minutes later, I feel another "bip", and I know the break is over. The app returns to "Work" time. 25 minutes later, I feel another "bip" and I know the game is over. Now I can stop the app cycling between "Work" and "Rest" times, or if I forget, I'll feel another "bip". Oops, I forgot the stop the app.

## Scenario 2

I want to prepare dinner. I want a "bip" every 10 minutes. I configure the app with an "Work" time of 10 minutes, and a "Rest" time of "10" minutes. I start cooking. I put the pot of water on. 10 minutes later, I hear and feel the "bip". It's time to put the rice in the water, and the food in the oven. 10 minutes later, the rice is ready. I feel the "bip", I take the pot off the heat, and turn down the oven, while I start serving up. I stop the app, and I get no more alerts/bips.

## Scenario 3

I'm 3D printing some copies of toys. Each will take 45 minutes. I configure "bip" with an "Work" time of 45 minutes, and a "Rest" time of 10 minutes. I start the print. 45 minutes later, I get the "bip", and remove the finished print from the build plate. The app is now in "Rest" time. But 10 minutes is a long time to clear everything for the next print, so I press a button (or some other interaction) and bring forward the next "Work" phase. I start the print. 45 minutes later, I get another "bip"

## Scenario 4

I'm at the Gym. I want to do 3 sets of 10 reps. After my 10 reps, I want a rest time of 100 seconds. I know that it takes me about 50 seconds to do 1 set of 10 reps. I configure bip to have an "Work" time of 50 seconds, and a "Rest" time of 100 seconds. I start "bip", and do my first set. After 50 seconds, I've done 9 reps, and I hear/feel the "bip". I'm now in recovery time. I finish my last rep, and try to relax. After 100 seconds, I feel the "bip" and I start my second set.


## Requirements

* Written in Swift and SwiftUI
* Optimised for iPhone 13 Mini and Apple Watch Series 8 (That's the hardware I have)
* Supports iOS 18.6.4 and Apple Watch 11.6.2 (That's the versions my hardware is running)
* Sticks very closely to Apples Human Interface Guidelines. I want this to be the most Apple like app ever. And I don't mean Tim Cook's Apple, or Jony Ive's Apple. I mean Steve Job's Apple.
* The bip tone should be configurable. I think iOS comes with a range of alert tones built in. Can we use those?
* The haptic tone should be configurable. I think there are some default ones? Maybe the user can choose and preview from a list?
* The default phasing should be "Work" phase, "Rest" phase (ie two phases), and should repeat for ever.
* But an advanced setting should let the user choose the total number of phases (ie 4 Work and 4 Rest phases, then stop)
* A super advanced setting should let the user choose different time periods for each phase. 15 minutes Work, then 5 minute Rest, 20 minutes Work, then 2 minutes Rest, etc.
* I'm am open to using a different naming convention for the "Work" / "Rested" states. I actually don't think it's good at all, but it's just what popped into mind as I was writing this. Please suggest a better or range of better alternatives. Maybe the user could even pick their own labels for each phase like: "First Half", "Half Time", "Second Half", "Boil Water", "Cook Rice", "Print", "Clear Buildplate".
* The timers should be configured from the Phone and can be stopped/started from the phone, but the user should be able to see a list of previous "Bips" and stop/start/monitor them from the watch.
* The watch app should have a complication because Apps that have a complication on the active watch face will stay active in the Apple Watche's memory.

# Bip — Setup Guide

## Requirements

- Xcode 16+
- iOS deployment target: 18.6
- watchOS deployment target: 11.6
- Tested on iPhone 13 Mini + Apple Watch Series 8

## Project Setup

1. Open Xcode → File → New → Project
2. Choose **iOS → App** template, name it **Bip**
3. Add a **watchOS App** target: File → New → Target → Watch App for iOS App
    - Name: BipWatch
    - Ensure “Include Notification Scene” is OFF
4. Add an **App Group** capability to both targets:
    - Signing & Capabilities → + Capability → App Groups
    - Group ID: group.com.yourname.bip (replace with your bundle prefix)
    - Update the APP_GROUP_ID constant in Models.swift accordingly
5. Copy source files from this ZIP into your project:
    - Shared/*.swift → add to BOTH targets (iOS + watchOS)
    - iOS/*.swift → iOS target only
    - watchOS/*.swift → watchOS target only
6. In your watchOS target, enable **Background Modes**: Workout Processing
7. Build & run on device (simulator haptics are limited)

## Sound Files

Bip ships with 8 bundled tones in `Bip/Sounds/` (included in both iOS and watchOS targets):

- Bip.wav
- Blep.wav
- Bloop.wav
- Bop.wav
- Done.wav
- Go.wav
- Pew Pew.wav
- Rest.wav

Users can select their preferred sound via the SoundPickerView. The app falls back to haptic-only if sound files are missing.

## App Group ID

Search for APP_GROUP_ID in Models.swift and replace with your actual group ID.

## Watch Complication

After installing on device, long-press your watch face → Edit → Complications, then select Bip from the list. The complication shows current phase + time remaining.

## Roadmap

See [To Do list](TODO.md)
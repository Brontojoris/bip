# Features and Fixes

This file is a list of ideas and improvements to be made to the Bip and BipWatch apps.

* [x] [Unresponsive main list immediately after opening the app](.docs/01-unresponsive-main-list.md).
* [x] [Add edit/pencil icon to each item in the main list](.docs/02-edit-pencil-icon.md).
* [ ] [Add stop button or icon to the current active timer](.docs/03-stop-button-active-timer.md).
* [ ] [Or when tapping the stop button on the timer RunningView make it more obvious that the timer is stopped and deleted, and return to the main list](.docs/04-stop-action-feedback.md).
* [x] [Consider whether stopping a timer should really delete it?](.docs/05-stop-vs-delete-design.md)
* [ ] [Use a more visual interactive clock UI for choosing the times instead of a slider](.docs/06-clock-ui-time-picker.md).
* [x] [Allow for shorter times than 30 seconds](.docs/07-shorter-times.md).
* [ ] [Improve the haptics. Stronger/more obvious](.docs/08-improve-haptics.md).
* [ ] [When pressing the Skip button on the RunningView, the line segment in the graph looks bad. It should neatly complete the circle to make it clear to the user that the timer has progressed to the next phase](.docs/09-skip-arc-fix.md).
* [ ] [Allow the user to swipe to delete the currently active timer](.docs/10-swipe-delete-active-timer.md).
* [ ] [Retain timer settings between app installs/upgrades](.docs/11-retain-settings.md).
* [x] [When the Bip app is in the background, notification sounds and haptics aren't triggered](.docs/12-background-sounds-haptics.md).
* [x] [BipWatch does not display a timer until the Rest phase is triggered](.docs/13-watch-timer-display-delay.md).
* [x] [BipWatch UI defect: Red heading "Quick Intervals" is overlaid on to of the "Rest" word](.docs/14-watch-ui-text-overlay.md).
* [x] [BipWatch timer doesn't actually count down](.docs/15-watch-timer-no-countdown.md).
* [ ] [Feature: Display a list of available timers in the BipWatch app](.docs/16-watch-timer-list.md).
* [ ] [Modernise watch complication: replace deprecated ClockKit with WidgetKit](.docs/17-complication-widgetkit.md).

| #   | TODO                                           | Complexity            |
| --- |------------------------------------------------| --------------------- |
| 01  | ~~Unresponsive main list on launch~~           | Low                   |
| 02  | ~~Add edit/pencil icon to list items~~         | Low                   |
| 03  | Add stop button/icon to active timer           | Low                   |
| 04  | Make stop action more obvious in RunningView   | Low                   |
| 05  | ~~Reconsider stop = delete behaviour~~         | Low (design decision) |
| 06  | Visual clock UI for time picking               | High                  |
| 07  | ~~Allow times shorter than 30 seconds~~        | Low                   |
| 08  | Improve haptics                                | Medium                |
| 09  | Fix skip button arc in progress ring           | Medium                |
| 10  | Swipe to delete active timer                   | Low                   |
| 11  | Retain settings across installs                | Medium                |
| 12  | ~~Background notification sounds and haptics~~ | High                  |
| 13  | ~~Watch: no display until Rest phase~~         | Medium                |
| 14  | ~~Watch: red heading overlays phase label~~    | Low                   |
| 15  | ~~Watch: timer doesn't count down~~            | Medium                |
| 16  | Watch: display list of available timers        | Medium                |
| 17  | Watch: modernise complication (WidgetKit)      | High                  |

## User Feedback

See [User Testing document](./docs/user-testing.md)
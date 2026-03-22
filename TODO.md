# Features and Fixes

This file is a list of ideas and improvements to be made to the Bip and BipWatch apps.

* [ ] Unresponsive main list immediately after opening the app.
* [ ] Add edit/pencil icon to each item in the main list.
* [ ] Add stop button or icon to the current active timer.
* [ ] Or when tapping the stop button on the timer RunningView make it more obvious that the timer is stopped and deleted, and return to the main list.
* [ ] Consider whether stopping a timer should really delete it?
* [ ] Use a more visual interactive clock UI for choosing the times instead of a slider.
* [ ] Allow for shorter times than 30 seconds
* [ ] Improve the haptics. Stronger/more obvious.
* [ ] When pressing the Skip button onr the RunningView, the line segment in the graph looks bad. It should neatly complete the circle to make it clear to the user that the timer has progressed to the next phase.
* [ ] Allow the user to swipe to delete the currently active timer.
* [ ] Retain timer settings between app installs/upgrades.

| #   | TODO                                         | Complexity            |
| --- | -------------------------------------------- | --------------------- |
| 01  | Unresponsive main list on launch             | Low                   |
| 02  | Add edit/pencil icon to list items           | Low                   |
| 03  | Add stop button/icon to active timer         | Low                   |
| 04  | Make stop action more obvious in RunningView | Low                   |
| 05  | Reconsider stop = delete behaviour           | Low (design decision) |
| 06  | Visual clock UI for time picking             | High                  |
| 07  | Allow times shorter than 30 seconds          | Low                   |
| 08  | Improve haptics                              | Medium                |
| 09  | Fix skip button arc in progress ring         | Medium                |
| 10  | Swipe to delete active timer                 | Low                   |
| 11  | Retain settings across installs              | Medium                |
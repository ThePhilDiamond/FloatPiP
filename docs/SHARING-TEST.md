# Is the floating picture left out of screen sharing?

Window Raft's window has `sharingType = .none`, which asks macOS to leave it out of screen captures. This records the test of whether macOS does.

## The test

On 22 November 2026, on macOS 26.6.2 (25G83), a MacBook Air with Apple silicon:

1. A test app put two plain windows of its own on screen: a magenta one with `sharingType = .none`, and a green one with `.readOnly` (the control, which should be captured).
2. It captured the whole screen with ScreenCaptureKit (an `SCStream` of the display, 2940 by 1912 pixels), with the display chosen in macOS's own picker (`SCContentSharingPicker`).
3. It read the pixel at the center of each of its two windows in the captured picture. Nothing was saved.

## The result

| Window | Pixel in the capture | Meaning |
|---|---|---|
| Magenta, `.none` | (255, 255, 255), the screen behind it | Left out |
| Green, `.readOnly` | green | Captured |

One run.

## What wasn't tested

- A capture of the whole screen set up without macOS's picker, as apps with the Screen Recording permission can (`SCShareableContent`). Both go through the same macOS window server, so the same result is expected.
- Each video-calling app's own way of sharing the screen. Apps built on older capture methods, or on their own drivers, may differ. Check with the person watching the first time you use one.
- Other macOS versions.

If a capture ever includes Window Raft, an app can leave it out by its bundle ID, `io.github.thephildiamond.FloatPiP`.

# Security

## Reporting a problem

Please report security problems privately, not as a public issue: on this repository, open the **Security** tab and choose **Report a vulnerability** ([direct link](https://github.com/ThePhilDiamond/FloatPiP/security/advisories/new)). Only the maintainer can read it, and you'll get a reply there. Say what you found, how to reproduce it, and which version and macOS version you used.

A floating picture that shows up in someone's screen share counts: it is the one thing FloatPiP promises not to do.

## Supported versions

The latest release. Fixes go into a new release rather than older ones.

## What FloatPiP can see and do

- **One window, chosen by you.** FloatPiP shows macOS's own window picker (ScreenCaptureKit's `SCContentSharingPicker`) and captures only the window picked there, only while its floating picture is showing. macOS shows its screen-sharing icon in the menu bar the whole time, and stopping from there stops FloatPiP.
- **No Screen Recording permission.** Because the window is chosen in macOS's picker, FloatPiP never asks for the permission that would let it capture the screen or other windows by itself.
- **Window list, without contents.** Once a second FloatPiP reads macOS's window list for the chosen window's number, size, and whether it still exists (`CGWindowListCopyWindowInfo`), to follow a resize and to stop when it closes. Without the Screen Recording permission, macOS gives no window titles or contents this way.
- **Nothing saved.** Captured pictures go straight to the screen and are discarded. The only things written to disk are the options (corner, size, shape, and screen) in FloatPiP's own preferences.
- **No network.** FloatPiP makes no network connections at all.
- **No administrator password**, and no helper tools, background services, or login items.

## The floating picture and screen sharing

FloatPiP's window is marked `sharingType = .none`, which asks macOS to leave it out of screen captures. macOS honored this in a test on macOS 26.6.2 ([docs/SHARING-TEST.md](docs/SHARING-TEST.md)), but FloatPiP can't control how each sharing app captures the screen. Check with the person watching the first time you use a new app.

## Builds

Release builds are made by GitHub Actions from the tagged code ([.github/workflows/release.yml](.github/workflows/release.yml)) and are ad-hoc signed, not notarized by Apple. Check a download against `SHA256SUMS.txt` on the release page:

```bash
shasum -a 256 ~/Downloads/FloatPiP-v0.1.0.zip
```

Put the version you downloaded in place of `v0.1.0`; the result must match the line in `SHA256SUMS.txt`.

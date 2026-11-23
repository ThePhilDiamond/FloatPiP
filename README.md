# Window Raft

<img src="docs/images/logo.png" alt="Window Raft's icon" width="128" align="right">

Watch one window in a small floating picture while you share your screen, without the people watching your share seeing it.

## What it is

Window Raft is a small, free, open-source macOS menu bar app. Pick any window, such as a video call, and Window Raft shows it live in a floating picture in a corner of your screen, on top of everything, on every desktop and over full-screen apps. macOS leaves the floating picture out of what you share (see [Left out of screen sharing](#left-out-of-screen-sharing)), so you can keep an eye on the call while you share something else.

Window Raft was called FloatPiP until version 0.2.0.

## Privacy

- Window Raft sees only the window you pick in macOS's own window picker, and only while it is floating. It needs no Screen Recording permission.
- Nothing is saved: each picture is drawn on screen and discarded.
- No account, no analytics. Window Raft goes online only to check GitHub for a newer version, a minute after it opens and then once a day (turn that off in its menu), and to download an update you choose to install. See [docs/UPDATES.md](docs/UPDATES.md).

## System requirements

macOS 26 or later, on a Mac with Apple silicon.

## Quick start

1. Download `WindowRaft-vX.Y.Z.zip` from the [Releases page](../../releases), open it, and drag Window Raft to your Applications folder. (To build it yourself instead, see [BUILDING.md](BUILDING.md).)
2. Open Window Raft. Because it isn't notarized by Apple yet, macOS may ask you to confirm the first time: choose **Open**, or go to System Settings ▸ Privacy & Security and choose **Open Anyway**.
3. macOS's window picker appears: click the window you want to float, then click **Share Window**. That is macOS's own wording, which Window Raft can't change; a note at the top of the screen says so. Nothing is shared: the window only floats on your screen.

Window Raft's icon, a small picture afloat on rippling water, appears in the menu bar, not the Dock.

## Options

Click the menu bar icon, or right-click the floating picture:

- **Pick a Window / Pick Another Window**: opens macOS's window picker; a new choice replaces the current window.
- **Stop**: closes the floating picture.
- **Position**: Snap to Corners (the default) or Stay Where Dropped. Drag the picture to move it: with Snap to Corners it settles into the nearest corner of the screen you drop it on, as macOS's own picture in picture does; with Stay Where Dropped it stays where you let go, kept wholly on screen.
- **Size (Height of Screen)**: the picture's height as a share of the screen's height, from 10% to 90% (30% by default).
- **Shape**: Rounded (the default) and Rectangle (sharp corners) show the whole window, never stretched; Circle shows the middle of it.
- **Zoom (Center of Window)**: 100% shows the whole window; 125% to 400% show its center larger, cutting away the edges, such as a call app's buttons. Scroll or pinch on the picture to zoom in 10% steps or smoothly.
- **Hide from Screen Sharing** (on by default): keeps the picture out of screen sharing. A small note on the picture says whether people watching your share can see it; it shows for a few seconds when the picture appears, and whenever the pointer is over it.
- **Show Sharing Note on Picture** (on by default): turn the note off if you find it distracting.

Window Raft remembers your choices. It stops by itself when the window closes, or when you stop it from macOS's screen-sharing icon in the menu bar.

## How it looks

The picture floats the way macOS and calling apps show floating video, with no border:

- It sits 3% of the screen's height in from the edges, clear of the menu bar and Dock.
- Rounded corners are 12% of the picture's height; a circle's radius is half its side.
- Two soft shadows lift it off the screen: a wide one (blur 10% of the picture's height, at least 4 points; 4% lower; 55% opacity) and a tight one (blur 2%, at least 1.5 points; 1% lower; 35%), with a white hairline 1 pixel wide at 35% opacity around the edge.

## Left out of screen sharing

Window Raft's window is marked as one macOS must not share (`NSWindow.sharingType = .none`). On macOS 26.6.2 this was tested: the marked window was left out of a capture of the whole screen, while a window from the same app that was not marked was captured. See [docs/SHARING-TEST.md](docs/SHARING-TEST.md) for how it was tested, and what wasn't. When you share a single window rather than your whole screen, the floating picture isn't in it anyway.

A video-calling app may draw its own preview of what you share. Check the first time that the people watching don't see the picture.

## Light on the Mac

Window Raft captures the window at the picture's own size, at most 30 frames a second, and only while it is showing.

## Contributing

Reports, ideas, and pull requests are welcome: see [CONTRIBUTING.md](CONTRIBUTING.md). Everyone taking part follows the [code of conduct](CODE_OF_CONDUCT.md). Security problems go through [SECURITY.md](SECURITY.md).

## License

Window Raft is free software under the [GNU AGPL v3.0 only](LICENSE), and is also available under a commercial license: see [COMMERCIAL.md](COMMERCIAL.md). Use of the app is covered by the [terms of use](TERMS.md). The name and icon are covered by [TRADEMARKS.md](TRADEMARKS.md). All changes are in [CHANGELOG.md](CHANGELOG.md).

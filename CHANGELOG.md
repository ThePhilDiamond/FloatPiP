# Changelog

All notable changes to Window Raft (called FloatPiP until 0.2.0) are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) as [RELEASING.md](RELEASING.md) describes. Changes waiting for the next release are in [changes/](changes/README.md).

## [Unreleased]

## [0.5.0] - 2026-11-26

### Changed

- The menu's Stop is now **Stop Floating**, and the Position submenu is now one **Snap to Corners** item: ticked, the picture settles into the nearest corner; unticked, it stays where you drop it.

### Fixed

- Stop Floating is now greyed out until you pick a window, and Checking for Updates… while a check or install runs. Before, both could still be chosen.

## [0.4.1] - 2026-11-23

### Fixed

- The update offer no longer closes when you want to read what's new: it now lists the release's changes itself, with a link to the release page that leaves the offer open. Before, its What's New button closed it, and you had to check for updates again. After you choose Later, the menu's Check for Updates item says an update is available and opens the offer again.

## [0.4.0] - 2026-11-23

### Changed

- Window Raft's icon and menu bar icon now have an oar beside the floating picture, its blade dipping into the ripples, so they show a raft as well as a window.

## [0.3.0] - 2026-11-23

### Added

- If macOS hides Window Raft's menu bar icon, as it does behind the camera notch when the menu bar is full, open Window Raft again from Finder or Spotlight to show its menu under the pointer.

### Changed

- Window Raft no longer opens the window picker when it starts, where the picker covered its menu bar icon. Choose Pick a Window… from its menu instead.

### Fixed

- macOS's screen-sharing indicator no longer stays in the menu bar, naming Window Raft, while nothing is floating. It shows only while you pick a window or one is floating.

## [0.2.0] - 2026-11-23

### Added

- A small note on the floating picture says whether people watching your screen share can see it, and the new Hide from Screen Sharing setting in the menu turns the hiding off and on.
- Stay Where Dropped: the picture can now stay wherever you drag it, instead of snapping to a corner.
- Zoom into the center of the floating window, from 100% (the whole window) to 400%, from the new Zoom menu, or by scrolling or pinching on the picture.
- Show Sharing Note on Picture, in the menu, turns the note about screen sharing off for anyone who finds it distracting; the note now says it can be hidden.
- While macOS's window picker is open, a note at the top of the screen explains that its Share Window button floats the window and shares nothing.
- Window Raft can update itself: it checks GitHub once a day (or when you choose Check for Updates…), and installs a new version only when you choose to and only if its signature checks out. Check for Updates Automatically, in the menu, turns the daily check off.

### Changed

- The Corner menu is now Position (Snap to Corners or Stay Where Dropped); you choose a corner by dragging the picture to it.
- FloatPiP is now called Window Raft. The app, its downloads, and its GitHub page use the new name, and your settings carry over. Delete the old FloatPiP app after you install Window Raft.

### Fixed

- The floating picture can now be dragged right up to the top of the screen, and the Top Left and Top Right corners place it just under the menu bar. Before, it stopped about an eighth of the way down the screen.

## [0.1.0] - 2026-11-22

### Added

- Float one window, picked in macOS's own window picker, in a picture in a corner of the screen, on top of everything, on every desktop and over full-screen apps.
- The picture is left out of screen sharing (tested on macOS 26.6.2).
- Choose its corner, its size (10% to 90% of the screen's height), and its shape (rounded, circle, or rectangle) from the menu bar icon or by right-clicking the picture.
- Drag the picture to move it; it snaps to the nearest corner. FloatPiP remembers your choices.
- The picture floats the way macOS and calling apps show floating video: two soft shadows and a faint hairline, with no border.

[Unreleased]: https://github.com/ThePhilDiamond/WindowRaft/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/ThePhilDiamond/WindowRaft/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/ThePhilDiamond/WindowRaft/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/ThePhilDiamond/WindowRaft/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/ThePhilDiamond/WindowRaft/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/ThePhilDiamond/WindowRaft/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ThePhilDiamond/WindowRaft/releases/tag/v0.1.0

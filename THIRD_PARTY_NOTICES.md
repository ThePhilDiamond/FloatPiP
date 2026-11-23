# Third-party notices

Window Raft has no third-party code dependencies, and uses no code, artwork, or other material from other projects. It is built only on Apple's own frameworks (AppKit, Core Animation, and ScreenCaptureKit), which come with macOS.

Its floating look (margins, corner radii, shadows, and hairline) uses the same numbers as the screen camera Window Raft's maintainer wrote for Mac.apk (https://github.com/kksimp/Mac.apk/pull/164, `runtime/src/screen_camera.mm`). No code was copied from it.

The in-app updater (`Sources/WindowRaft/Updater.swift`, `scripts/sign-update.swift`, `scripts/update-key.swift`, `docs/UPDATES.md`) is adapted from Cool Head's (https://github.com/ThePhilDiamond/CoolHead), another of the maintainer's projects, under the same license.

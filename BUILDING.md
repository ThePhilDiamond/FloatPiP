# Building FloatPiP

You need macOS 26 or later on Apple silicon, and the Xcode Command Line Tools. Xcode itself is not needed. To install the tools, open Terminal (it's in Applications ▸ Utilities) and run:

```bash
xcode-select --install
```

## The app

From the folder you downloaded or cloned FloatPiP into:

```bash
scripts/build-app.sh
```

This builds `build/FloatPiP.app`, ad-hoc signed, with its icon. Open it from Finder; it appears in the menu bar, not the Dock. Because the build is not notarized by Apple, macOS may ask you to confirm the first time you open it.

## The selftest

```bash
swift build -c release
```

```bash
.build/release/FloatPiP --selftest
```

The selftest checks the floating picture's layout (corners, sizes, shapes, margins, shadows, and capture size) and the remembered options, without opening a window or capturing anything. CI runs it on every pull request.

## The icon

The icon is drawn in code. To see the options side by side (`build/icon/sheet.png`):

```bash
swift scripts/make-icon.swift build/icon sheet
```

To redraw the chosen icon and the README's logo:

```bash
swift scripts/make-icon.swift build/icon app
```

```bash
iconutil -c icns build/icon/AppIcon.iconset -o Resources/AppIcon.icns
```

```bash
sips -z 512 512 build/icon/logo.png --out docs/images/logo.png
```

The menu bar icon is the small picture and its ripples from the same drawing, without the window (`menubob`), as a template image that macOS colors for light and dark menu bars:

```bash
swift scripts/make-icon.swift build/icon menu menubob
```

```bash
cp build/icon/MenuIcon.png build/icon/MenuIcon@2x.png Resources/
```

## Layout

- `Sources/FloatPiP/main.swift`: the menu bar item, its menu, and the glue between the picture and the capture.
- `Sources/FloatPiP/Capture.swift`: macOS's window picker and the live capture of the chosen window (ScreenCaptureKit).
- `Sources/FloatPiP/PiPPanel.swift`: the floating window, its shape, shadows, and hairline, and dragging.
- `Sources/FloatPiP/Layout.swift`: where the picture goes and how big it is.
- `Sources/FloatPiP/Settings.swift`: the remembered options.
- `Sources/FloatPiP/Selftest.swift`: `--selftest`.
- `Info.plist`: the app's bundle information; its version is `VERSION`'s.

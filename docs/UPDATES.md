# How FloatPiP updates itself

FloatPiP checks GitHub for a newer release a minute after it opens and then once a day. When one exists, its menu says so at the top, with **Install FloatPiP X.Y.Z…** and **What's New**. It never installs by itself, so nothing restarts during a call. To check now, choose **Check for Updates…** in its menu: it says FloatPiP is up to date, or offers to install. **Check for Updates Automatically**, in the same menu, turns the daily check off.

The design is Cool Head's updater (the same maintainer's project), adapted for FloatPiP's menu.

## What it sends

One request to GitHub's public API for the latest release of this repository. If you choose Install, the download of that release's zip and its signature. Nothing about you, your Mac, or the window you float; GitHub sees the request come from your internet address, as it does for any web page.

## How it knows the update is genuine

1. The release workflow signs each release zip with the project's private Ed25519 key (`scripts/sign-update.swift`), and publishes the signature (`.zip.sig`) beside it.
2. The matching public key is built into the app (`Sources/FloatPiP/Updater.swift`).
3. Before installing, the app checks the signature against that key, and refuses the update if it doesn't match, so a changed or substituted download is never installed.
4. It also checks the download is FloatPiP (same bundle identifier), at the version announced, with an intact code signature.
5. It checks the update can run on this Mac: the macOS version the update needs (its `LSMinimumSystemVersion`) against this Mac's. If this Mac is older, the update isn't installed, the working copy stays, FloatPiP says which macOS it needs, and that version isn't offered again.
6. It moves the running copy to the Trash (so it can be put back), puts the new one in its place, and reopens.

A release without a signature can't be installed from inside the app; FloatPiP says so and points to the release page. 0.1.0 has no updater, so its users download the next release by hand.

## The key

- The private key lives in two places only: the repository secret `UPDATE_SIGNING_KEY`, used by the release workflow, and the maintainer's password manager. It is never committed.
- It was made once, with `swift scripts/update-key.swift .secrets` (git ignores `.secrets`), which printed the public key for `Updater.swift`.
- If the private key is ever lost or exposed, make a new pair and ship a release with the new public key. Versions with the old key can't verify updates signed with the new one, so those users download that one release by hand.

## Testing

`FLOATPIP_UPDATE_TEST=1` makes a copy check at launch, install if there's an update, and report each step:

```bash
FLOATPIP_UPDATE_TEST=1 build/FloatPiP.app/Contents/MacOS/FloatPiP
```

The selftest checks version order, the macOS check, and that a correctly signed download verifies while a changed one, or one signed with another key, is refused.

## Not covered

FloatPiP isn't signed with an Apple Developer ID or notarized (that needs the paid Apple Developer Program), so the first download from a browser still needs **Open Anyway** in System Settings ▸ Privacy & Security. Updates installed from inside the app don't, because macOS only asks about apps downloaded by a browser.

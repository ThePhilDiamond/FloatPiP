# Releasing FloatPiP

How versions are numbered, what each release contains, and the steps to make one. Anyone can follow along; only the maintainer publishes.

## Version numbers

FloatPiP follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html): **MAJOR.MINOR.PATCH**, for example 0.1.0.

- **PATCH** (0.1.0 to 0.1.1): fixes only. Nothing new to learn.
- **MINOR** (0.1.0 to 0.2.0): anything new a user would notice, such as a new option or shape, with or without fixes.
- **MAJOR** (0.x to 1.0): saved for when FloatPiP is notarized and its behavior is settled. While the major number is 0, anything may still change.

One number names a version everywhere:

| Where | Looks like |
|---|---|
| `VERSION` file, and `CFBundleShortVersionString` in `Info.plist` | `0.1.0` |
| The app (its menu, above Quit) | `FloatPiP v0.1.0` |
| Git tag | `v0.1.0` |
| GitHub release title | `FloatPiP 0.1.0` |
| CHANGELOG.md heading | `## [0.1.0] - 2026-11-22` |
| Downloads | `FloatPiP-v0.1.0.zip`, `FloatPiP-v0.1.0.zip.sig`, `SHA256SUMS.txt` |

`scripts/check-version.sh` checks they agree. CI runs it on every change, and the release workflow runs it with the tag, so a release with mismatched numbers stops before anything is published.

## What a release contains

- **`FloatPiP-vX.Y.Z.zip`**: the app, built by GitHub from the tagged code, ad-hoc signed (not yet notarized).
- **`FloatPiP-vX.Y.Z.zip.sig`**: an Ed25519 signature of the zip. The in-app updater installs an update only if this checks out against the key built into the app (see [docs/UPDATES.md](docs/UPDATES.md)).
- **`SHA256SUMS.txt`**: the zip's checksum, to check a download by hand.
- **Notes**: copied from the version's section of [CHANGELOG.md](CHANGELOG.md), word for word.

## How changes reach main

Every change, the maintainer's included, goes through a pull request: `main` accepts nothing else, and the `build` check (version check, build, selftest, packaging) must pass before a squash merge. One approving review is required. The maintainer reviews and approves contributors' and Dependabot's pull requests. GitHub never lets an author approve their own pull request, so the maintainer's own pull requests are merged with the owner's bypass, and only after `build` passes. Dependabot opens pull requests to update the GitHub Actions the workflows use; each is merged once `build` passes, except an update to the release step (`softprops/action-gh-release`), which is read first and checked on the next release.

## Steps

1. **During development**, each change a user would notice gets its own file in [changes/](changes/README.md), under `added/`, `changed/`, or `fixed/`, so pull requests don't edit the same lines of CHANGELOG.md.
2. **Choose the number** by the rules above: MINOR if anything is in `changes/added` or `changes/changed`, PATCH if it's all in `changes/fixed`.
3. **Prepare the release** in one pull request named `Release X.Y.Z`:
   - Run `scripts/gather-changes.sh X.Y.Z`: it moves every entry in `changes/` into a new `## [X.Y.Z] - YYYY-MM-DD` section of CHANGELOG.md, oldest first, under Added, Changed, and Fixed, updates the links at the bottom, and removes the entry files. Read the section through before committing.
   - Set `VERSION` and `CFBundleShortVersionString` in `Info.plist` to X.Y.Z, and raise `CFBundleVersion` by one.
   - Run `scripts/check-version.sh vX.Y.Z`, `swift build -c release`, `.build/release/FloatPiP --selftest`, and `scripts/build-app.sh`.
4. **Merge, then tag**: once `build` passes, squash-merge the pull request, pull `main`, and tag the merged commit: `git tag -a vX.Y.Z -m "FloatPiP X.Y.Z"`, then push the tag. The release workflow checks the numbers, builds, runs the selftest, zips the app, and publishes the release with its title, notes, and downloads.
5. **Check the release**: the zip's checksum matches `SHA256SUMS.txt`, its signature verifies, the app's menu shows vX.Y.Z, and it floats a window.

## History

- 0.1.0 (22 November 2026) was the first commit on `main`, made before the pull request rule was applied. Every change since goes through a pull request.
- 0.1.0 has no updater and no `.sig` file: the in-app updater begins with the release after it, so 0.1.0 users download that one by hand.

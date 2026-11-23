# Contributing to Window Raft

Thanks for helping. There are three easy ways in.

## Report a problem

[Open an issue](../../issues/new/choose) with the Window Raft version (in its menu, above Quit), your macOS version, what you did, and what happened. If the floating picture closed by itself, its menu shows the reason in gray under Stop: include it. Leave out anything private, such as what was in the window: issues are public.

## Tell us if the picture showed up in a screen share

The point of Window Raft is that people watching your screen share don't see it. If they did, [open an issue](../../issues/new/choose) naming the app you shared with, how you shared (the whole screen or one window), and your macOS version. [docs/SHARING-TEST.md](docs/SHARING-TEST.md) says what has been tested.

## Suggest an idea

[Open an issue](../../issues/new/choose) saying what Window Raft should do and what problem that solves. Window Raft is meant to stay small, so ideas that keep it simple are the likeliest to be taken up.

## Send code

1. Read [BUILDING.md](BUILDING.md) and get a build running.
2. Make your change on a branch and open a pull request. Say what it changes and how you tested it.
3. `.build/release/WindowRaft --selftest` must pass; the CI runs it on every pull request. If your change moves or resizes the floating picture on purpose, update the expected numbers in `Sources/WindowRaft/Selftest.swift` and the README's "How it looks" in the same pull request, so the change shows in its diff.
4. The first time, the CLA bot asks you to sign the [Contributor License Agreement](CLA.md) by leaving a comment with the sentence it gives. You do this once for each version of the agreement, not on every pull request. It lets the project offer Window Raft under both licenses (see [COMMERCIAL.md](COMMERCIAL.md)); you keep your copyright, and what's published under the AGPL stays under the AGPL.
   - Everyone whose work is in the pull request signs for themselves, including every person named in a `Co-authored-by` line. Nobody signs for someone else.
   - Opening a pull request, or ticking a box in its description, isn't signing; only the bot's sentence is.
   - If you'd rather not sign, open an issue that describes the change instead.

### Using AI tools

You can use AI tools to help with a contribution. You're responsible for it as if you'd typed it: read and test every line, and make sure you have the right to submit it, as the [CLA](CLA.md) asks. An AI tool can't sign the CLA, so name it in an `Assisted-by:` line at the end of the commit message, not as a co-author, for example `Assisted-by: Claude Code:claude-opus-5-5`. Window Raft's own commits follow the same rule.

### How changes reach main

- Every change arrives as a pull request and is merged by squashing, so main reads as one commit per change.
- **Start every branch from main**, never from another pull request's branch. Squash merging gives main a new commit for each pull request, so a branch built on another one conflicts as soon as that one merges.
- **Write where no one else is writing**, so pull requests made at the same time don't conflict: a changelog entry is its own file in `changes/` (below), and lists that grow have one item per line. Two pull requests that must edit the same lines are made one after the other.
- The CI must pass (`build`: the version check, the build, the selftest, and packaging the app), and the maintainer reviews and approves.
- main can't be force-pushed or deleted. The rules are in [`.github/rulesets/protect-main.json`](.github/rulesets/protect-main.json), and `scripts/apply-repo-settings.sh` applies them along with the repository's other settings.

### Changelog and releases

If your change is something a user would notice, add one file for it in [changes/](changes/README.md): `changes/added/`, `changes/changed/`, or `changes/fixed/`, named in a few words joined by hyphens, holding one line in plain words that starts `- `. Don't edit CHANGELOG.md itself; the release gathers these files into it. Releases are made by the maintainer; how versions are numbered and every step of a release are in [RELEASING.md](RELEASING.md).

### Writing the docs

Write for someone who has never opened Terminal. Every step names where it happens and what to press ("Click the menu bar icon, then choose Corner ▸ Top Left"). Plain words, US English, the Oxford comma, no em dashes, and no exclamation marks.

### How the code is meant to work

- **Small.** Window Raft does one thing: float one window, out of the screen share. A feature earns its place by serving that.
- **Out of the share, always.** Nothing Window Raft draws on screen may appear in a screen capture. Every window it opens has `sharingType = .none`.
- **Only what the person picked.** Window Raft captures only the window chosen in macOS's picker, never asks for the Screen Recording permission, and saves nothing.
- **Everything stays on the Mac.** No analytics. The one network use is the update check against GitHub ([docs/UPDATES.md](docs/UPDATES.md)), which can be turned off.
- **Light on the Mac.** Capture at the picture's own size, at most 30 frames a second, and nothing while it is hidden. Check it in Activity Monitor.
- **The same look as macOS's floating video.** The shadows, hairline, margins, and radii in the README's "How it looks" are the design; change them only on purpose.
- **License-clean dependencies.** MIT, BSD, Apache-2.0, and similar only. No GPL, AGPL, or LGPL code linked into what ships, because it would stop Window Raft from being offered under a commercial license. The project has no dependencies today. Anything taken from another project, even an approach, is credited in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) with its license.
- **Comments explain why.**

## Code of conduct

Everyone taking part follows the [code of conduct](CODE_OF_CONDUCT.md). To report a problem privately, use the repository's **Security** tab, **Report a vulnerability**, with a title starting "Conduct:"; only the maintainer can read it.

## Security problems

See [SECURITY.md](SECURITY.md). Please don't open a public issue for those.

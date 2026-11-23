# Changes waiting for the next release

Each pull request that changes something a user would notice adds **one file** here, instead of editing [CHANGELOG.md](../CHANGELOG.md). Pull requests made at the same time then never edit the same lines, so they don't conflict.

- **Where:** `changes/added/`, `changes/changed/`, or `changes/fixed/`, as in [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
- **Name:** a few words about the change, lowercase, joined by hyphens: `changes/added/circle-shape.md`.
- **What:** one bullet, starting `- `, in plain words for someone who uses Window Raft, the way CHANGELOG.md's entries read. Sub-bullets, indented two spaces, are fine.

At release, `scripts/gather-changes.sh X.Y.Z` moves every entry into a new dated section of CHANGELOG.md, oldest first, and removes the files (see [RELEASING.md](../RELEASING.md)). `scripts/check-version.sh`, run on every build, checks each entry is in the right folder and starts with `- `.

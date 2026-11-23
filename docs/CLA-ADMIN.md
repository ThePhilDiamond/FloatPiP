# Running the CLA

These notes are for the maintainer, who doesn't sign: the agreement licenses contributors' work to the maintainer, who already owns his own, and `ThePhilDiamond` is on the workflow's allowlist. They cover how signatures to the [Contributor License Agreement](../CLA.md) are collected, how to check a pull request, and what to do when the agreement changes. Contributors only need [CONTRIBUTING.md](../CONTRIBUTING.md).

## What gets recorded

The [CLA workflow](../.github/workflows/cla.yml) runs on every pull request. A contributor signs by posting the sentence for the current version (for version 1.0: "I have read Window Raft CLA version 1.0 and I hereby sign it"). The action stores their GitHub account name and number, the pull request, and the time in `signatures/cla-<version>.json` (`signatures/cla-1.0.json` for version 1.0) on the `cla-signatures` branch.

The action doesn't store the agreement's text, so the version in the sentence is what links a signature to the text that was signed. After a new version merges, tag the merge commit `cla-<version>` (for version 1.0, `cla-1.0`) so that text is easy to find.


## Checking a pull request

- The check covers commit authors who have GitHub accounts. It doesn't read `Co-authored-by` lines, so ask each person named in one to sign before merging (a line naming an AI tool names no one who can sign).
- A commit made through GitHub's website or API by an author with no GitHub account passes as `web-flow`, which stays on the allowlist for Dependabot. On a pull request from outside the project, read its commit authors in Terminal with `gh pr view <number> --json commits`, putting the pull request's number in place of `<number>` (for example `gh pr view 61 --json commits`), and ask anyone who hasn't signed to sign.
- A pull request opened by a bot or coding agent on a person's behalf needs that person to sign. Bots are allowlisted by name only, never with a wildcard.
- Never sign for anyone, and never mark the check as passed by hand. If the action isn't working, wait for it.
- If someone agreed some other way, such as by email, ask them to sign on the pull request as well: that's the record the check reads.

## Changing the agreement

1. Any change to CLA.md, even to its wording, is a new version: a new number and date at the top, because people agree to the text they read.
2. In `cla.yml`, change the signing sentence (in the `if:` line and in `custom-pr-sign-comment`), the version in `custom-notsigned-prcomment`, and the signatures file name. Earlier signatures stay in their own file; someone who signed an earlier version signs again on their next pull request.
3. In the pull request, list each change to the terms in plain words, with who it affects, and have a lawyer review it before merging.
4. After it merges, tag the merge commit as above.

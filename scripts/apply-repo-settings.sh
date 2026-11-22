#!/bin/bash
# Applies FloatPiP's GitHub settings from this repository, so they are reviewable and repeatable.
# Safe to run again. Needs the GitHub CLI (gh), signed in as a repository admin.
#
# - Always: description, topics, merge settings (squash only, delete merged branches).
# - Once the repository is public (GitHub allows these on private repositories only with GitHub Pro):
#   the "Protect main" ruleset (.github/rulesets/protect-main.json), private vulnerability reporting
#   (SECURITY.md relies on it), Dependabot alerts and security updates, secret scanning and push protection.
set -euo pipefail
REPO=ThePhilDiamond/FloatPiP

gh api -X PATCH "repos/$REPO" --silent \
  -f description="Watch one window in a small floating picture while you share your screen, without the people watching your share seeing it. A free, open-source macOS menu bar app. Nothing saved, nothing online." \
  -f homepage="https://github.com/ThePhilDiamond" \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -F allow_auto_merge=false \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
  -F has_issues=true
gh api -X PUT "repos/$REPO/topics" --silent \
  -f 'names[]=macos' -f 'names[]=menu-bar-app' -f 'names[]=swift' -f 'names[]=appkit' -f 'names[]=apple-silicon' \
  -f 'names[]=picture-in-picture' -f 'names[]=pip' -f 'names[]=screencapturekit' -f 'names[]=screen-sharing' \
  -f 'names[]=floating-window' -f 'names[]=always-on-top' -f 'names[]=video-call' -f 'names[]=privacy' -f 'names[]=open-source'
echo "Settings and topics applied."

if [ "$(gh api "repos/$REPO" --jq .private)" = "true" ]; then
  echo "The repository is private: the ruleset and security features are applied when it goes public (run this again then)."
  exit 0
fi

existing=$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name == "Protect main") | .id')
if [ -n "$existing" ]; then
  gh api -X PUT "repos/$REPO/rulesets/$existing" --input .github/rulesets/protect-main.json --silent
else
  gh api -X POST "repos/$REPO/rulesets" --input .github/rulesets/protect-main.json --silent
fi
echo "Ruleset \"Protect main\" applied."

gh api -X PUT "repos/$REPO/private-vulnerability-reporting" --silent
gh api -X PUT "repos/$REPO/vulnerability-alerts" --silent
gh api -X PUT "repos/$REPO/automated-security-fixes" --silent
gh api -X PATCH "repos/$REPO" --silent \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
echo "Private vulnerability reporting, Dependabot alerts and fixes, secret scanning and push protection on."

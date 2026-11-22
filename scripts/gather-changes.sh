#!/bin/sh
# For a release: gathers the change entries in changes/ into a new dated section of CHANGELOG.md, updates the links at
# its bottom, and removes the entries. Each pull request adds its own file to changes/added, changes/changed or
# changes/fixed instead of editing CHANGELOG.md, so pull requests made at the same time don't edit the same lines.
#   scripts/gather-changes.sh 0.6.0               dated today
#   scripts/gather-changes.sh 0.6.0 2026-11-16    dated as given
# Entries appear oldest first, by when each was added to git. See RELEASING.md and changes/README.md.
set -e
cd "$(dirname "$0")/.."
fail() { echo "gather-changes: $1"; exit 1; }
v=$1; day=${2:-$(date +%Y-%m-%d)}
echo "$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail "give the version as X.Y.Z"
grep -q "^## \[$v\]" CHANGELOG.md && fail "CHANGELOG.md already has a [$v] section"
prev=$(sed -n 's|^\[Unreleased\]: .*/compare/v\(.*\)\.\.\.HEAD$|\1|p' CHANGELOG.md)
[ -n "$prev" ] || fail "CHANGELOG.md has no [Unreleased] link at the bottom"
repo=$(sed -n 's|^\[Unreleased\]: \(.*\)/compare/.*$|\1|p' CHANGELOG.md)

section=$(mktemp); found=0
printf '## [%s] - %s\n' "$v" "$day" > "$section"
for kind in added changed fixed; do
  files=$(for f in changes/$kind/*.md; do
            [ -f "$f" ] || continue
            t=$(git log --diff-filter=A --format=%ct -1 -- "$f"); echo "${t:-9999999999} $f"
          done | sort -k1,1n -k2 | cut -d' ' -f2-)
  [ -n "$files" ] || continue
  title=$(echo "$kind" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  printf '\n### %s\n\n' "$title" >> "$section"
  for f in $files; do
    head -c 2 "$f" | grep -q '^- ' || fail "$f doesn't start with \"- \""
    cat "$f" >> "$section"; found=$((found + 1))
  done
done
[ "$found" -gt 0 ] || fail "changes/ has no entries"
printf '\n' >> "$section"

# the new section goes above the latest release's; the links get the new version
awk -v sec="$section" -v v="$v" -v prev="$prev" -v repo="$repo" '
  !done && /^## \[[0-9]/ { while ((getline line < sec) > 0) print line; done = 1 }
  /^\[Unreleased\]: / { print "[Unreleased]: " repo "/compare/v" v "...HEAD"; print "[" v "]: " repo "/compare/v" prev "...v" v; next }
  { print }' CHANGELOG.md > CHANGELOG.md.new
mv CHANGELOG.md.new CHANGELOG.md
rm "$section"
for kind in added changed fixed; do
  for f in changes/$kind/*.md; do [ -f "$f" ] && git rm -q "$f"; done
done
echo "Gathered $found entries into CHANGELOG.md as [$v] - $day."

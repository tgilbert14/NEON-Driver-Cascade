#!/usr/bin/env bash
# Copy and structure gate for the GitHub Pages cover (docs/index.html).
# Fails on: an em dash (raw U+2014 or its HTML entity forms), a <title> without
# the app's name, an <html> tag without lang="en", or more than one <h1>.
# Usage: scripts/check_cover.sh [path/to/index.html]   (default docs/index.html)
set -euo pipefail

file="${1:-docs/index.html}"
name="NEON Cross-Product Response Atlas"
failures=0

fail() {
  printf 'check_cover: FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

if [[ ! -f "$file" ]]; then
  printf 'check_cover: FAIL: %s not found\n' "$file" >&2
  exit 2
fi

# Em dash as raw UTF-8 bytes (E2 80 94) or as an entity. Byte-level match, so it
# does not depend on the shell locale.
dash_lines=$(LC_ALL=C grep -n -i -e $'\xe2\x80\x94' -e '&mdash;' -e '&#8212;' -e '&#x2014;' "$file" | cut -d: -f1 | paste -sd, - || true)
if [[ -n "$dash_lines" ]]; then
  fail "em dash (U+2014 or &mdash;) on line(s) $dash_lines"
fi

# <title> must carry the app's name. Collapse newlines so a wrapped title still matches.
title=$(tr '\n' ' ' < "$file" | LC_ALL=C grep -o -i '<title>[^<]*</title>' | head -n 1 || true)
if [[ -z "$title" ]]; then
  fail "no <title> element"
elif [[ "$title" != *"$name"* ]]; then
  fail "<title> does not contain \"$name\": $title"
fi

# <html ...> must declare lang="en".
html_tag=$(tr '\n' ' ' < "$file" | LC_ALL=C grep -o -i '<html[^>]*>' | head -n 1 || true)
if [[ -z "$html_tag" ]]; then
  fail "no <html> tag"
elif ! LC_ALL=C grep -q -i -E "lang=[\"']?en[\"' >]" <<< "$html_tag "; then
  fail "<html> tag lacks lang=\"en\": $html_tag"
fi

# Exactly one <h1> at most. grep -o | wc -l counts occurrences, not lines.
h1_count=$(LC_ALL=C grep -o -i -E '<h1([[:space:]>])' "$file" | wc -l | tr -d '[:space:]')
if (( h1_count > 1 )); then
  fail "$h1_count <h1> elements (expected at most one)"
fi

if (( failures > 0 )); then
  printf 'check_cover: %d failure(s) in %s\n' "$failures" "$file" >&2
  exit 1
fi
printf 'check_cover: ok (%s)\n' "$file"

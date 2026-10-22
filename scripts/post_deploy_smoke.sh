#!/usr/bin/env bash

# Cold-start-aware semantic production check for the Cross-Product Response
# Atlas, ported from the NEON Plant Diversity and Mosquito Pulse smoke scripts.
# Posit host error pages can return HTTP 200, so the Connect response must carry
# the app shell (the tabset id="tabs" with its About tab), and the app is then
# driven in headless Chromium until the About tab's "Snapshot and provenance"
# fold shows the exact built_when of the pushed bundle (SMOKE_BUILT_WHEN).
#
# Every page must also carry the app name in its <title> (SMOKE_TITLE), and the
# app must declare <html lang="en">. built_when proves the data; the code
# revision is proved by fetching the static assets the app serves (the paths in
# its own HTML, from ui.R asset_url()) and requiring each md5 to equal the
# checked-out file under SMOKE_ASSET_ROOT (default www). The ?v= query is a file
# mtime, not a revision, so only the bytes count. Every check shares the same
# retry and deadline budget.
#
# usage: post_deploy_smoke.sh '<label>=<url>' ...
#   A label ending in "app" gets the app marker, title, lang and asset checks
#   and, with SMOKE_BROWSER=1, the browser check; any other label is a cover
#   page and needs SMOKE_COVER_MARKER and the title.

set -uo pipefail

MAX_ATTEMPTS="${SMOKE_MAX_ATTEMPTS:-12}"
SLEEP_BASE="${SMOKE_SLEEP_BASE:-10}"
CONNECT_TIMEOUT="${SMOKE_CONNECT_TIMEOUT:-15}"
MAX_TIME="${SMOKE_MAX_TIME:-45}"
TOTAL_DEADLINE="${SMOKE_TOTAL_DEADLINE:-900}"
APP_MARKER="${SMOKE_APP_MARKER:-data-value=\"about\"}"
APP_NAME="${SMOKE_TITLE:-NEON Cross-Product Response Atlas}"
COVER_MARKER="${SMOKE_COVER_MARKER:-$APP_NAME}"
ASSET_ROOT="${SMOKE_ASSET_ROOT:-www}"
# Space-separated www/ file names whose live bytes must match the checkout.
ASSETS="${SMOKE_ASSETS:-cascade.js cascade.css styles.css}"
USER_AGENT='ddl-response-atlas-semantic-smoke/1.0'
failed=0
deadline_at=$((SECONDS + TOTAL_DEADLINE))

find_chromedriver() {
  local driver
  driver=$(command -v chromedriver || true)
  if [[ -z "$driver" && -n "${CHROMEWEBDRIVER:-}" && -x "${CHROMEWEBDRIVER}/chromedriver" ]]; then
    driver="${CHROMEWEBDRIVER}/chromedriver"
  fi
  printf '%s' "$driver"
}

check_browser_ready() {
  local label="$1" url="$2" driver browser_timeout remaining
  if [[ -z "${SMOKE_BUILT_WHEN:-}" ]]; then
    echo "DOWN [$label] SMOKE_BUILT_WHEN (the expected built_when) was not configured"
    return 1
  fi
  driver=$(find_chromedriver)
  if [[ -z "$driver" ]]; then
    echo "DOWN [$label] semantic browser requested but ChromeDriver is unavailable"
    return 1
  fi
  remaining=$((deadline_at - SECONDS))
  browser_timeout="${SMOKE_BROWSER_TIMEOUT:-150}"
  ((browser_timeout > remaining)) && browser_timeout=$remaining
  if ((browser_timeout < 10)); then
    echo "DOWN [$label] shared smoke deadline elapsed before browser readiness"
    return 1
  fi
  python3 scripts/chromedriver_semantic_smoke.py \
    --url "$url" \
    --built-when "$SMOKE_BUILT_WHEN" \
    --title "$APP_NAME" \
    --timeout "$browser_timeout" \
    --driver "$driver"
}

file_md5() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" | awk '{print $1}'
  else
    md5 -q "$1"
  fi
}

# Prints a reason and returns 1 when the page <title> lacks APP_NAME, or (for
# the app) when <html lang="en"> is missing.
check_title_lang() {
  local label="$1" body="$2" title
  title=$(tr '\n' ' ' < "$body" | grep -oiE '<title[^>]*>[^<]*</title>' | head -n 1)
  if [[ "$title" != *"$APP_NAME"* ]]; then
    echo "page <title> is '${title:-absent}', expected it to contain '$APP_NAME'"
    return 1
  fi
  if [[ "$label" == *"app" ]] && ! grep -Eqi '<html[^>]*[[:space:]]lang="en"' "$body"; then
    echo "<html lang=\"en\"> is absent"
    return 1
  fi
  return 0
}

# Prints a reason and returns 1 unless every served asset's md5 equals the
# checked-out copy. The served path comes from the app's own HTML.
check_assets() {
  local url="$1" body="$2" name ref asset_url fetched want got request_max
  fetched=$(mktemp)
  for name in $ASSETS; do
    if [[ ! -f "$ASSET_ROOT/$name" ]]; then
      echo "checked-out asset $ASSET_ROOT/$name is missing"
      rm -f "$fetched"
      return 1
    fi
    ref=$(grep -oE "(href|src)=\"[^\"]*${name//./[.]}([?][^\"]*)?\"" "$body" | head -n 1 |
      sed -E 's/^(href|src)="//; s/"$//')
    if [[ -z "$ref" ]]; then
      echo "the app HTML does not reference $name"
      rm -f "$fetched"
      return 1
    fi
    case "$ref" in
      http://* | https://*) asset_url="$ref" ;;
      /*) asset_url="$(printf '%s' "$url" | grep -oE '^https?://[^/]+')$ref" ;;
      *) asset_url="${url%/}/$ref" ;;
    esac
    request_max=$MAX_TIME
    ((request_max > deadline_at - SECONDS)) && request_max=$((deadline_at - SECONDS))
    ((request_max < 1)) && request_max=1
    if ! curl -fsS -o "$fetched" -L --connect-timeout "$CONNECT_TIMEOUT" \
      --max-time "$request_max" -A "$USER_AGENT" "$asset_url" 2>/dev/null; then
      echo "could not fetch $asset_url"
      rm -f "$fetched"
      return 1
    fi
    want=$(file_md5 "$ASSET_ROOT/$name")
    got=$(file_md5 "$fetched")
    if [[ "$want" != "$got" ]]; then
      echo "live $name md5 $got differs from checked-out $want (an older code revision is still served)"
      rm -f "$fetched"
      return 1
    fi
    echo "ok asset $name md5 $got matches the checkout" >&2
  done
  rm -f "$fetched"
  return 0
}

check_one() {
  local label="$1" url="$2" body attempt code nap marker remaining request_max reason
  body=$(mktemp)
  marker="$COVER_MARKER"
  [[ "$label" == *"app" ]] && marker="$APP_MARKER"

  for ((attempt = 1; attempt <= MAX_ATTEMPTS; attempt++)); do
    remaining=$((deadline_at - SECONDS))
    if ((remaining <= 0)); then
      echo "wait [$label] shared smoke deadline elapsed"
      break
    fi
    request_max=$MAX_TIME
    ((request_max > remaining)) && request_max=$remaining
    code=$(curl -sS -o "$body" -w '%{http_code}' -L \
      --connect-timeout "$CONNECT_TIMEOUT" --max-time "$request_max" \
      -A "$USER_AGENT" "$url" 2>/dev/null || echo "000")
    if [[ "$code" =~ ^(2|3)[0-9][0-9]$ ]]; then
      if grep -Eqi 'startup error|application failed to start|application error|service unavailable' "$body"; then
        echo "wait [$label] HTTP $code but host error page detected ($attempt/$MAX_ATTEMPTS)"
      elif ! grep -Fq "$marker" "$body"; then
        echo "wait [$label] HTTP $code but semantic marker is absent ($attempt/$MAX_ATTEMPTS)"
      elif ! reason=$(check_title_lang "$label" "$body"); then
        echo "wait [$label] HTTP $code but $reason ($attempt/$MAX_ATTEMPTS)"
      elif [[ "$label" == *"app" ]] && ! reason=$(check_assets "$url" "$body"); then
        echo "wait [$label] HTTP $code but $reason ($attempt/$MAX_ATTEMPTS)"
      else
        echo "ok [$label] HTTP $code + semantic marker + title (attempt $attempt)"
        if [[ "$label" == *"app" && "${SMOKE_BROWSER:-0}" == "1" ]]; then
          if check_browser_ready "$label" "$url"; then
            rm -f "$body"
            return 0
          fi
          echo "wait [$label] app shell is live but the About tab does not yet show built_when ${SMOKE_BUILT_WHEN:-} ($attempt/$MAX_ATTEMPTS)"
        else
          rm -f "$body"
          return 0
        fi
      fi
    else
      echo "wait [$label] HTTP $code ($attempt/$MAX_ATTEMPTS)"
    fi
    ((attempt >= MAX_ATTEMPTS)) && break
    remaining=$((deadline_at - SECONDS))
    ((remaining <= 1)) && break
    nap=$((SLEEP_BASE * attempt))
    ((nap > 60)) && nap=60
    ((nap >= remaining)) && nap=$((remaining - 1))
    ((nap > 0)) && sleep "$nap"
  done
  rm -f "$body"
  echo "DOWN [$label] semantic health not reached"
  return 1
}

if [[ $# -eq 0 ]]; then
  echo "usage: $0 '<label>=<url>' ..." >&2
  exit 2
fi

for spec in "$@"; do
  label="${spec%%=*}"
  url="${spec#*=}"
  if [[ -z "$label" || -z "$url" || "$url" == "$spec" ]]; then
    echo "invalid smoke target: $spec" >&2
    exit 2
  fi
  if ! check_one "$label" "$url"; then failed=1; fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "::error title=Production smoke failed::the Cross-Product Response Atlas did not reach semantic health (expected built_when ${SMOKE_BUILT_WHEN:-unset}, title '$APP_NAME', and the checked-out asset md5s)"
  echo "post-deploy semantic smoke FAILED" >&2
  exit 1
fi
echo "post-deploy semantic smoke PASSED"

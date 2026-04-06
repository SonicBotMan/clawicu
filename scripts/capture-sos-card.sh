#!/usr/bin/env bash
# Rasterize public/sos-card.svg -> public/sos-card.png (1200x630) via headless Chrome.
# Edit the SVG, then run: npm run build:share-card
# Linux: export CHROME_PATH=/usr/bin/chromium (or google-chrome)

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HTML="file://${ROOT}/public/sos-card-render.html"
OUT="${ROOT}/public/sos-card.png"

if [[ "$(uname -s)" == "Darwin" ]]; then
  CHROME="${CHROME_PATH:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
else
  CHROME="${CHROME_PATH:-}"
fi

if [[ ! -x "$CHROME" ]] && command -v google-chrome-stable &>/dev/null; then
  CHROME="$(command -v google-chrome-stable)"
fi
if [[ ! -x "$CHROME" ]] && command -v chromium &>/dev/null; then
  CHROME="$(command -v chromium)"
fi
if [[ ! -x "$CHROME" ]]; then
  echo "Chrome/Chromium not found. Set CHROME_PATH or install Google Chrome." >&2
  exit 1
fi

"$CHROME" --headless=new --disable-gpu --window-size=1200,630 --hide-scrollbars \
  --screenshot="$OUT" "$HTML"

echo "Wrote $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"

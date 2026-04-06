#!/usr/bin/env bash
# Rasterize public/sos-card.svg -> public/sos-card.png (1200x630) via headless Chrome.
# Embeds the SVG inline (avoids <img> load timing + filter clipping issues).
# Run: npm run build:share-card

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="${ROOT}/public/sos-card.svg"
RENDER="${ROOT}/public/sos-card-render.html"
OUT="${ROOT}/public/sos-card.png"

if [[ ! -f "$SVG" ]]; then
  echo "Missing $SVG" >&2
  exit 1
fi

# Single-file HTML: inline SVG so the viewport is exactly 1200x630 with no async decode
{
  printf '%s\n' '<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"/><style>'
  printf '%s\n' 'html,body{margin:0;padding:0;width:1200px;height:630px;overflow:hidden;background:#050810;}'
  printf '%s\n' 'svg{display:block;width:1200px;height:630px;vertical-align:top;}'
  printf '%s\n' '</style></head><body>'
  cat "$SVG"
  printf '%s\n' '</body></html>'
} > "$RENDER"

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

# force-device-scale-factor=1 avoids HiDPI viewport vs CSS px mismatch; virtual-time-budget waits for fonts/filters
"$CHROME" --headless=new \
  --disable-gpu \
  --force-device-scale-factor=1 \
  --hide-scrollbars \
  --window-size=1200,630 \
  --virtual-time-budget=4000 \
  --screenshot="$OUT" \
  "file://${RENDER}"

echo "Wrote $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"

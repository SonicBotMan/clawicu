#!/usr/bin/env bash
# Capture README assets: terminal mock + static site over HTTP (file:// breaks Next /_next/ assets).
# Prerequisites: npm run build
# Usage: npm run build && npm run build:readme-screenshots

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${ROOT}/docs/readme"
TERMINAL_HTML="${ROOT}/scripts/readme-screenshots/terminal-mock.html"
STATIC_ROOT="${ROOT}/out"

mkdir -p "$OUT_DIR"

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
  echo "Chrome/Chromium not found. Set CHROME_PATH." >&2
  exit 1
fi

if [[ ! -f "${STATIC_ROOT}/index.html" ]]; then
  echo "Missing ${STATIC_ROOT}/index.html — run: npm run build" >&2
  exit 1
fi

capture() {
  local url="$1"
  local dest="$2"
  local w="$3"
  local h="$4"
  "$CHROME" --headless=new \
    --disable-gpu \
    --force-device-scale-factor=1 \
    --hide-scrollbars \
    --window-size="${w},${h}" \
    --virtual-time-budget=12000 \
    --screenshot="$dest" \
    "$url"
  echo "  -> $dest ($(wc -c < "$dest" | tr -d ' ') bytes)"
}

echo "==> Terminal mock"
capture "file://${TERMINAL_HTML}" "${OUT_DIR}/terminal-rescue.png" 960 620

# Serve static export — required for correct JS/CSS loading
PORT="${README_SCREENSHOT_PORT:-47991}"
cd "$STATIC_ROOT"
python3 -m http.server "$PORT" >/tmp/clawicu-readme-http.log 2>&1 &
HTTP_PID=$!
cleanup() { kill "$HTTP_PID" 2>/dev/null || true; }
trap cleanup EXIT
sleep 0.8

BASE="http://127.0.0.1:${PORT}"

echo "==> Website (homepage) via ${BASE}/"
capture "${BASE}/" "${OUT_DIR}/website-home.png" 1440 900

echo "==> Website (docs hub)"
capture "${BASE}/docs/" "${OUT_DIR}/website-docs.png" 1440 900

echo "Done. Files in ${OUT_DIR}/"

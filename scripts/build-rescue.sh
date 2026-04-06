#!/bin/sh
# build-rescue.sh - Bundles all rescue modules into a single rescue.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RESCUE_DIR="$PROJECT_DIR/rescue"
OUTPUT_FILE="$PROJECT_DIR/dist/rescue.sh"

echo "Building ClawICU rescue script..."

# Create output directory
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Write header
cat > "$OUTPUT_FILE" << 'HEADER'
#!/bin/sh
# ClawICU - OpenClaw Emergency Rescue System
# Bundled rescue script - auto-generated
# DO NOT EDIT - edit source files and rebuild

set -e

CLAWICU_VERSION="0.1.0"
CLAWICU_TMPDIR="${CLAWICU_TMPDIR:-/tmp/clawicu-$$}"
HEADER

# Inline lib modules
echo "" >> "$OUTPUT_FILE"
echo "# === LIBRARIES ===" >> "$OUTPUT_FILE"

for lib in bootstrap log ui backup state verify; do
    echo "" >> "$OUTPUT_FILE"
    echo "# --- lib/$lib.sh ---" >> "$OUTPUT_FILE"
    grep -v '^#!/' "$RESCUE_DIR/lib/$lib.sh" >> "$OUTPUT_FILE" || true
done

# Inline check modules
echo "" >> "$OUTPUT_FILE"
echo "# === CHECK MODULES ===" >> "$OUTPUT_FILE"

for check in "$RESCUE_DIR/checks"/check-*.sh; do
    echo "" >> "$OUTPUT_FILE"
    echo "# --- $(basename "$check") ---" >> "$OUTPUT_FILE"
    # Strip shebang and source/dot commands (libs are already inlined above)
    grep -v '^#!/' "$check" | grep -v '^\. "' >> "$OUTPUT_FILE" || true
done

# Inline repair modules
echo "" >> "$OUTPUT_FILE"
echo "# === REPAIR MODULES ===" >> "$OUTPUT_FILE"

for repair in "$RESCUE_DIR/repairs"/repair-*.sh; do
    echo "" >> "$OUTPUT_FILE"
    echo "# --- $(basename "$repair") ---" >> "$OUTPUT_FILE"
    # Strip shebang and source/dot commands (libs are already inlined above)
    grep -v '^#!/' "$repair" | grep -v '^\. "' >> "$OUTPUT_FILE" || true
done

# Inline main rescue.sh (without lib sourcing)
echo "" >> "$OUTPUT_FILE"
echo "# === MAIN ORCHESTRATOR ===" >> "$OUTPUT_FILE"
grep -v '^#!/' "$RESCUE_DIR/rescue.sh" | grep -v '^\. "' | grep -v 'bootstrap$' | grep -v 'main "' >> "$OUTPUT_FILE" || true

# Make executable
chmod +x "$OUTPUT_FILE"

echo "Built: $OUTPUT_FILE"
echo "Size: $(wc -c < "$OUTPUT_FILE") bytes"

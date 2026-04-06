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

CLAWICU_VERSION="0.2.0"
CLAWICU_TMPDIR="${CLAWICU_TMPDIR:-/tmp/clawicu-$$}"
HEADER

# Helper: inline a file stripping shebang, source lines, and bare 'set -e'.
# In a bundled script every module's 'set -e' stacks dangerously; the single
# 'set -e' in the bundle header is enough.
inline_file() {
    local file="$1"
    grep -v '^#!/'   "$file" \
        | grep -v '^\. "' \
        | grep -v '^set -e' \
        >> "$OUTPUT_FILE" || true
}

# Inline lib modules
echo "" >> "$OUTPUT_FILE"
echo "# === LIBRARIES ===" >> "$OUTPUT_FILE"

for lib in bootstrap log ui backup state verify; do
    echo "" >> "$OUTPUT_FILE"
    echo "# --- lib/$lib.sh ---" >> "$OUTPUT_FILE"
    inline_file "$RESCUE_DIR/lib/$lib.sh"
done

# Inline check modules
echo "" >> "$OUTPUT_FILE"
echo "# === CHECK MODULES ===" >> "$OUTPUT_FILE"

for check in "$RESCUE_DIR/checks"/check-*.sh; do
    echo "" >> "$OUTPUT_FILE"
    echo "# --- $(basename "$check") ---" >> "$OUTPUT_FILE"
    inline_file "$check"
done

# Inline repair modules
echo "" >> "$OUTPUT_FILE"
echo "# === REPAIR MODULES ===" >> "$OUTPUT_FILE"

for repair in "$RESCUE_DIR/repairs"/repair-*.sh; do
    echo "" >> "$OUTPUT_FILE"
    echo "# --- $(basename "$repair") ---" >> "$OUTPUT_FILE"
    inline_file "$repair"
done

# Generate function dispatch lists so the bundled script can call check/repair
# functions directly without needing files on disk (curl | sh mode).
echo "" >> "$OUTPUT_FILE"
echo "# === BUNDLED DISPATCH LISTS ===" >> "$OUTPUT_FILE"

CHECK_FNS=""
for check in "$RESCUE_DIR/checks"/check-*.sh; do
    fn="$(basename "$check" .sh | sed 's/^check-//' | tr '-' '_')"
    CHECK_FNS="${CHECK_FNS:+$CHECK_FNS }$fn"
done
REPAIR_FNS=""
for repair in "$RESCUE_DIR/repairs"/repair-*.sh; do
    fn="$(basename "$repair" .sh | sed 's/^repair-//' | tr '-' '_')"
    REPAIR_FNS="${REPAIR_FNS:+$REPAIR_FNS }$fn"
done
printf '_CLAWICU_CHECK_FNS="%s"\n' "$CHECK_FNS"  >> "$OUTPUT_FILE"
printf '_CLAWICU_REPAIR_FNS="%s"\n' "$REPAIR_FNS" >> "$OUTPUT_FILE"

# Inline main rescue.sh (without shebang and lib sourcing lines)
echo "" >> "$OUTPUT_FILE"
echo "# === MAIN ORCHESTRATOR ===" >> "$OUTPUT_FILE"
inline_file "$RESCUE_DIR/rescue.sh"

# Make executable
chmod +x "$OUTPUT_FILE"

echo "Built: $OUTPUT_FILE"
echo "Size: $(wc -c < "$OUTPUT_FILE") bytes"

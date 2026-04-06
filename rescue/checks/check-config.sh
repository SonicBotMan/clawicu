# check-config.sh - Detect invalid JSON5 config file
#
# OpenClaw config: ~/.openclaw/openclaw.json (JSON5 format, unquoted keys allowed)
# Reference: https://docs.openclaw.ai/gateway/configuration

check_config() {
    SEVERITY="fatal"

    # OpenClaw config is always ~/.openclaw/openclaw.json
    local config_path="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"

    # Accept legacy .json5 extension as fallback
    if [ ! -f "$config_path" ]; then
        local alt="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}/openclaw.json5"
        [ -f "$alt" ] && config_path="$alt"
    fi

    if [ ! -f "$config_path" ]; then
        # Missing config is not fatal — OpenClaw uses safe defaults when absent
        SEVERITY="warn"
        MESSAGE="Config file not found: $config_path"
        DETAILS="OpenClaw will use built-in defaults. Run 'openclaw onboard' to create one."
        return 0
    fi

    # Empty file is always broken
    local size
    size=$(wc -c < "$config_path" 2>/dev/null || echo 0)
    if [ "$size" -eq 0 ]; then
        MESSAGE="Config file is empty: $config_path"
        DETAILS="Run 'openclaw doctor --fix' or restore from backup"
        return 0
    fi

    # Preferred: let OpenClaw validate its own config (catches schema errors too)
    if command -v openclaw >/dev/null 2>&1; then
        if openclaw config validate 2>/dev/null; then
            return 1   # no issue
        else
            MESSAGE="Config file failed OpenClaw schema validation"
            DETAILS="Run 'openclaw doctor' for details, or 'openclaw doctor --fix' to auto-repair"
            return 0
        fi
    fi

    # Fallback: structural brace balance check
    local open_count close_count
    open_count=$(grep -o '{' "$config_path" | wc -l)
    close_count=$(grep -o '}' "$config_path" | wc -l)

    if [ "$open_count" -ne "$close_count" ]; then
        MESSAGE="Config file has unbalanced braces (${open_count} '{' vs ${close_count} '}')"
        DETAILS="Edit $config_path to fix the syntax"
        return 0
    fi

    if ! grep -q '}' "$config_path"; then
        MESSAGE="Config file appears incomplete (no closing brace)"
        DETAILS="Edit $config_path to fix the syntax"
        return 0
    fi

    # Fallback: try Python3 JSON5-lenient parse
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "
import re, json, sys
txt = open(sys.argv[1]).read()
txt = re.sub(r'//.*', '', txt)
txt = re.sub(r'/\*.*?\*/', '', txt, flags=re.DOTALL)
txt = re.sub(r',\s*([}\]])', r'\1', txt)
json.loads(txt)
" "$config_path" 2>/dev/null; then
            MESSAGE="Config file has invalid JSON5 syntax"
            DETAILS="Run 'openclaw doctor' for details or restore from backup"
            return 0
        fi
    elif command -v node >/dev/null 2>&1; then
        # Node: attempt JSON.parse after stripping comments/trailing commas
        if ! node -e "
const fs = require('fs');
let txt = fs.readFileSync(process.argv[1], 'utf8');
txt = txt.replace(/\/\/.*/g, '').replace(/\/\*[\s\S]*?\*\//g, '').replace(/,\s*([}\]])/g, '\$1');
JSON.parse(txt);
" "$config_path" 2>/dev/null; then
            MESSAGE="Config file has invalid JSON5 syntax"
            DETAILS="Run 'openclaw doctor' for details or restore from backup"
            return 0
        fi
    fi

    return 1   # no issue detected
}

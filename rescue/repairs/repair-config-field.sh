#!/bin/sh
# repair-config-field.sh - Reset individual OpenClaw config fields to defaults
#
# OpenClaw config is at ~/.openclaw/openclaw.json (JSON5 format).
# Config fields use dot-notation paths, e.g. gateway.port, gateway.bind.
# The preferred method is 'openclaw config set <path> <value>'.
# Python3 / Node.js are used as fallbacks when the binary is unavailable.

set -e

. "$(dirname "$0")/../lib/bootstrap.sh"
. "$(dirname "$0")/../lib/backup.sh"
. "$(dirname "$0")/../lib/state.sh"
. "$(dirname "$0")/../lib/log.sh"

repair_config_field() {
    # Known resettable fields: dot-notation path → default value
    # Values are strings; numeric/boolean types are cast by the setter.
    _field_defaults() {
        case "$1" in
            gateway.port)      echo "18789" ;;
            gateway.bind)      echo "loopback" ;;
            gateway.mode)      echo "local" ;;
            gateway.auth.mode) echo "token" ;;
            agents.defaults.workspace) echo "~/.openclaw/workspace" ;;
            *)                 echo "" ;;
        esac
    }

    _known_fields() {
        echo "gateway.port       - Gateway WebSocket port (default: 18789)"
        echo "gateway.bind       - Bind mode: loopback|lan|auto|tailnet (default: loopback)"
        echo "gateway.mode       - Gateway mode (default: local)"
        echo "gateway.auth.mode  - Auth mode: token|password|none (default: token)"
        echo "agents.defaults.workspace - Agent workspace path (default: ~/.openclaw/workspace)"
    }

    describe() {
        echo "Reset individual OpenClaw config fields to their default values"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Back up current config"
        echo "  - Reset the specified field to its default value"
        echo "  - Verify config is still valid JSON5"
        echo "  - Roll back if verification fails"
        echo ""
        echo "Known resettable fields:"
        _known_fields
    }

    _validate_json5() {
        local cfg="$1"
        [ -f "$cfg" ] || return 1
        local size
        size=$(wc -c < "$cfg" 2>/dev/null || echo 0)
        [ "$size" -eq 0 ] && return 1

        # Prefer openclaw's own validation if the binary is available
        if command -v openclaw >/dev/null 2>&1; then
            openclaw config validate 2>/dev/null && return 0
        fi

        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import re, json, sys
txt = open(sys.argv[1]).read()
txt = re.sub(r'//.*', '', txt)
txt = re.sub(r'/\*.*?\*/', '', txt, flags=re.DOTALL)
txt = re.sub(r',\s*([}\]])', r'\1', txt)
json.loads(txt)
" "$cfg" 2>/dev/null && return 0
        fi

        if command -v node >/dev/null 2>&1; then
            node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$cfg" 2>/dev/null && return 0
        fi

        grep -q '{' "$cfg" 2>/dev/null && return 0
        return 1
    }

    # Set a dot-notation config path to a value.
    # Preferred: 'openclaw config set <path> <value>'
    # Fallback: Python3 with nested key traversal, then Node.js.
    _set_field() {
        local cfg="$1"
        local field="$2"    # dot-notation: e.g. gateway.port
        local value="$3"

        # Best: delegate to the official CLI (handles JSON5 format and schema)
        if command -v openclaw >/dev/null 2>&1; then
            openclaw config set "$field" "$value" 2>/dev/null && return 0
        fi

        # Fallback: Python3 with dot-notation path traversal
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import re, json, sys

def set_nested(d, path, val):
    keys = path.split('.')
    for k in keys[:-1]:
        if k not in d or not isinstance(d[k], dict):
            d[k] = {}
        d = d[k]
    # Cast numeric and boolean values
    if val.isdigit():
        val = int(val)
    elif val == 'true':
        val = True
    elif val == 'false':
        val = False
    d[keys[-1]] = val

path_arg, field_arg, val_arg = sys.argv[1], sys.argv[2], sys.argv[3]
txt = open(path_arg).read()
# Strip JS-style comments and trailing commas for parsing
txt = re.sub(r'//.*', '', txt)
txt = re.sub(r'/\*.*?\*/', '', txt, flags=re.DOTALL)
txt = re.sub(r',\s*([}\]])', r'\1', txt)
d = json.loads(txt)
set_nested(d, field_arg, val_arg)
with open(path_arg, 'w') as f:
    json.dump(d, f, indent=2)
" "$cfg" "$field" "$value" 2>/dev/null && return 0
        fi

        # Fallback: Node.js with dot-notation path traversal
        if command -v node >/dev/null 2>&1; then
            node -e "
const fs = require('fs');
const [cfgPath, fieldPath, rawVal] = process.argv.slice(1);
const obj = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
const keys = fieldPath.split('.');
let cur = obj;
for (let i = 0; i < keys.length - 1; i++) {
    if (!cur[keys[i]] || typeof cur[keys[i]] !== 'object') cur[keys[i]] = {};
    cur = cur[keys[i]];
}
const last = keys[keys.length - 1];
cur[last] = /^\d+\$/.test(rawVal) ? Number(rawVal)
          : rawVal === 'true'  ? true
          : rawVal === 'false' ? false
          : rawVal;
fs.writeFileSync(cfgPath, JSON.stringify(obj, null, 2));
" "$cfg" "$field" "$value" 2>/dev/null && return 0
        fi

        log_fatal "Need openclaw, python3, or node to modify config fields"
        return 1
    }

    execute() {
        log_info "Starting config field reset repair..."

        # OpenClaw config: ~/.openclaw/openclaw.json
        local config_dir="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
        local config_file="$config_dir/openclaw.json"

        # Accept legacy .json5 extension
        [ ! -f "$config_file" ] && config_file="$config_dir/openclaw.json5"

        if [ ! -f "$config_file" ]; then
            log_fatal "Cannot find config file: $config_dir/openclaw.json"
            return 1
        fi

        local field="${OPENCLAW_RESET_FIELD:-}"
        if [ -z "$field" ]; then
            log_info "Available fields to reset:"
            _known_fields
            log_fatal "Set OPENCLAW_RESET_FIELD env var to the field path (e.g. gateway.port)"
            return 1
        fi

        local default_val
        default_val="$(_field_defaults "$field")"
        if [ -z "$default_val" ]; then
            log_fatal "Unknown field: $field"
            log_info "Known fields:"
            _known_fields
            return 1
        fi

        log_info "Resetting '$field' → '$default_val'"

        # Direct config file snapshot for rollback (backup_create returns a
        # tar.gz of the state dir and cannot be cp'd back as a config file).
        local config_snapshot="${config_file}.clawicu-$(date '+%Y%m%d-%H%M%S').bak"
        cp "$config_file" "$config_snapshot"
        log_info "Config snapshot saved: $config_snapshot"

        backup_create "repair-config-field" >/dev/null
        state_push "repair-config-field"

        if ! _set_field "$config_file" "$field" "$default_val"; then
            log_error "Failed to set field, rolling back..."
            cp "$config_snapshot" "$config_file"
            rm -f "$config_snapshot"
            state_rollback
            return 1
        fi

        if _validate_json5 "$config_file"; then
            rm -f "$config_snapshot"
            log_info "Field '$field' reset to '$default_val' successfully"
            return 0
        else
            log_error "Config validation failed after field reset, rolling back..."
            cp "$config_snapshot" "$config_file"
            rm -f "$config_snapshot"
            state_rollback
            return 1
        fi
    }
}

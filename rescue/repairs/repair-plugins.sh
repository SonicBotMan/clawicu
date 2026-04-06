# repair-plugins.sh - Disable plugins that crash or use deprecated APIs

repair_plugins() {
    describe() {
        echo "Disable OpenClaw plugins with runtime errors or API compatibility issues"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Run 'openclaw doctor' and parse output for plugin errors"
        echo "  - Identify broken plugin IDs and file paths"
        echo "  - Rename broken plugin entry-point to .disabled (non-destructive)"
        echo "  - OR set plugins.allow to exclude broken plugins"
        echo "  - Verify 'openclaw doctor' passes after disabling"
    }

    # Parse doctor output file for the broken plugin's JS file path
    # Returns: absolute path to the plugin's main JS file, or empty string
    _find_broken_plugin_path() {
        local doctor_out="${CLAWICU_DOCTOR_OUT:-}"
        [ -f "$doctor_out" ] || return 1
        # "at activate (/path/to/plugin/dist-node/index.js:LINE:COL)"
        # grep -o '(/[^)]*)' matches the whole "(path:line:col)" group
        grep "at activate" "$doctor_out" 2>/dev/null | head -1 \
            | grep -o '(/[^)]*)' | tr -d '()' | sed 's/:[0-9]*:[0-9]*$//'
    }

    # Parse doctor output file for the broken plugin's ID
    # Returns: plugin ID string (e.g. "workflow-orchestration"), or empty string
    _find_broken_plugin_id() {
        local doctor_out="${CLAWICU_DOCTOR_OUT:-}"
        [ -f "$doctor_out" ] || return 1
        # "│  - WARN workflow-orchestration: plugin register returned a promise"
        # Use sed to extract the identifier after "WARN "
        grep "plugin register returned a promise\|async registration is ignored" "$doctor_out" 2>/dev/null \
            | head -1 | sed 's/.*WARN[[:space:]]*\([a-zA-Z0-9_-]*\):.*/\1/'
    }

    # Get all plugin IDs that are currently loaded (from doctor output)
    _list_all_plugin_ids() {
        local doctor_out="${CLAWICU_DOCTOR_OUT:-}"
        [ -f "$doctor_out" ] || return 1
        # "plugins.allow is empty; discovered non-bundled plugins may auto-load: id1 (...), id2 (...),"
        grep "plugins.allow is empty" "$doctor_out" 2>/dev/null \
            | grep -o '[a-zA-Z0-9_-]*[[:space:]]*(/' \
            | sed 's/[[:space:]]*(\/$//'
    }

    # Disable by renaming the entry-point JS file (non-destructive, reversible)
    _disable_by_rename() {
        local js_path="$1"
        if [ -z "$js_path" ] || [ ! -f "$js_path" ]; then
            return 1
        fi
        local backup="${js_path}.clawicu-disabled"
        if mv "$js_path" "$backup" 2>/dev/null; then
            log_info "Disabled: $js_path -> $backup"
            log_info "To re-enable: mv \"$backup\" \"$js_path\""
            return 0
        fi
        log_warn "Could not rename $js_path"
        return 1
    }

    # Set plugins.allow to exclude the broken plugin ID
    # Requires: openclaw config set plugins.allow '[...]'
    _disable_by_allowlist() {
        local broken_id="$1"
        [ -z "$broken_id" ] && return 1

        # Build allow list from currently discovered plugins, excluding the broken one
        local all_ids
        all_ids="$(_list_all_plugin_ids)"

        local allow_list=""
        for id in $all_ids; do
            if [ "$id" != "$broken_id" ]; then
                if [ -z "$allow_list" ]; then
                    allow_list="\"$id\""
                else
                    allow_list="$allow_list,\"$id\""
                fi
            fi
        done

        if [ -z "$allow_list" ]; then
            log_warn "Could not build plugin allow list - no plugin IDs found in doctor output"
            return 1
        fi

        if command -v openclaw >/dev/null 2>&1; then
            openclaw config set plugins.allow "[$allow_list]" 2>/dev/null && return 0
        fi

        # Manual fallback: edit openclaw.json directly
        local cfg="$HOME/.openclaw/openclaw.json"
        if [ -f "$cfg" ] && command -v node >/dev/null 2>&1; then
            node - "$cfg" "$broken_id" "$allow_list" <<'JSEOF'
const fs = require('fs');
const file = process.argv[2];
const brokenId = process.argv[3];
let raw = fs.readFileSync(file, 'utf8');
// Strip JS-style comments (JSON5)
raw = raw.replace(/\/\/[^\n]*/g, '').replace(/\/\*[\s\S]*?\*\//g, '');
let cfg;
try { cfg = JSON.parse(raw); } catch(e) { cfg = {}; }
if (!cfg.plugins) cfg.plugins = {};
// Build allow list excluding broken plugin
const current = Array.isArray(cfg.plugins.allow) ? cfg.plugins.allow : [];
// If allow was empty (auto-load all), we don't know all IDs - just set deny instead
if (current.length === 0) {
    cfg.plugins.deny = (cfg.plugins.deny || []).filter(x => x !== brokenId).concat([brokenId]);
} else {
    cfg.plugins.allow = current.filter(x => x !== brokenId);
}
fs.writeFileSync(file, JSON.stringify(cfg, null, 2));
console.log('Updated config:', JSON.stringify(cfg.plugins));
JSEOF
            return $?
        fi

        return 1
    }

    execute() {
        log_info "Starting plugin repair..."

        local doctor_out="${CLAWICU_DOCTOR_OUT:-}"

        if [ ! -f "$doctor_out" ]; then
            log_info "No doctor output file found, running openclaw doctor now..."
            CLAWICU_DOCTOR_OUT="$CLAWICU_TMPDIR/doctor-output.txt"
            openclaw doctor > "$CLAWICU_DOCTOR_OUT" 2>&1 || true
            doctor_out="$CLAWICU_DOCTOR_OUT"
            export CLAWICU_DOCTOR_OUT
        fi

        # Check if there is actually a problem
        if ! grep -q "Unhandled promise rejection\|is not a function\|is not defined\|plugin register returned a promise" \
                "$doctor_out" 2>/dev/null; then
            log_info "No plugin errors detected in doctor output"
            return 0
        fi

        local broken_path
        broken_path="$(_find_broken_plugin_path)"
        local broken_id
        broken_id="$(_find_broken_plugin_id)"

        log_info "Broken plugin path: ${broken_path:-not detected}"
        log_info "Broken plugin ID:   ${broken_id:-not detected}"

        local repaired=0

        # Strategy 1: Disable by renaming the entry-point JS (most reliable)
        if [ -n "$broken_path" ]; then
            printf "   [*] Disabling broken plugin: %s\n" "$broken_path"
            if _disable_by_rename "$broken_path"; then
                repaired=1
                printf "   [OK] Plugin disabled (entry-point renamed to .clawicu-disabled)\n"
                printf "   [i]  To re-enable: mv \"%s.clawicu-disabled\" \"%s\"\n" "$broken_path" "$broken_path"
            fi
        fi

        # Strategy 2: Also update plugins config to add to deny list (belt & suspenders)
        if [ -n "$broken_id" ]; then
            printf "   [*] Adding '%s' to plugins.deny in config...\n" "$broken_id"
            if _disable_by_allowlist "$broken_id"; then
                repaired=1
                printf "   [OK] Config updated: plugin '%s' is now excluded\n" "$broken_id"
            else
                log_warn "Could not update plugins config automatically"
                printf "   [!] Manual fix: run: openclaw config set plugins.deny '[\"${broken_id}\"]'\n"
            fi
        fi

        if [ "$repaired" -eq 0 ]; then
            log_warn "Could not automatically disable the broken plugin"
            printf "   [!] Manual steps:\n"
            [ -n "$broken_path" ] && printf "       mv \"%s\" \"%s.disabled\"\n" "$broken_path" "$broken_path"
            [ -n "$broken_id" ]   && printf "       openclaw config set plugins.deny '[\"${broken_id}\"]'\n"
            return 1
        fi

        # Verify fix
        printf "   [*] Verifying repair (running openclaw doctor)...\n"
        local verify_out="$CLAWICU_TMPDIR/doctor-verify.txt"
        openclaw doctor > "$verify_out" 2>&1 || true
        if grep -q "Unhandled promise rejection\|is not a function" "$verify_out" 2>/dev/null; then
            log_warn "Plugin errors still present after repair"
            return 1
        else
            printf "   [OK] Verification passed - no more plugin runtime errors\n"
        fi

        return 0
    }
}

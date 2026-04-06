# repair-plugins-sdk.sh - Fix plugin SDK compatibility issues
# Handles: ERR_MODULE_NOT_FOUND (plugin-sdk), api.config.get incompatibility,
#          and invalid plugins.load.paths entries

repair_plugins_sdk() {
    describe() {
        echo "Fix plugin SDK module missing or API incompatibility issues"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Detect root cause: module missing vs API incompatibility vs bad paths"
        echo "  - For ERR_MODULE_NOT_FOUND: attempt npm install in the plugin directory"
        echo "  - For api.config.get / API error: disable the offending plugin (rename .js -> .clawicu-disabled)"
        echo "  - For invalid plugins.load.paths: remove non-existent entries from config"
    }

    # Re-parse doctor output to get current details
    _sdk_doctor_out() {
        echo "${CLAWICU_DOCTOR_OUT:-}"
    }

    # Find path of the plugin with SDK import error
    _find_sdk_plugin_path() {
        local doc="$(_sdk_doctor_out)"
        [ -f "$doc" ] || return 1
        grep "imported from\|ERR_MODULE_NOT_FOUND" "$doc" 2>/dev/null | head -1 \
            | grep -o '/[^ ]*\.js' | head -1
    }

    # Find path of the plugin with API incompatibility (at activate ...)
    _find_api_broken_path() {
        local doc="$(_sdk_doctor_out)"
        [ -f "$doc" ] || return 1
        grep "at activate" "$doc" 2>/dev/null | head -1 \
            | grep -o '(/[^)]*)' | tr -d '()' | sed 's/:[0-9]*:[0-9]*$//'
    }

    # Find plugin ID from "WARN id: plugin register returned a promise" line
    _find_api_broken_id() {
        local doc="$(_sdk_doctor_out)"
        [ -f "$doc" ] || return 1
        grep "plugin register returned a promise\|async registration is ignored" "$doc" 2>/dev/null \
            | head -1 | sed 's/.*WARN[[:space:]]*\([a-zA-Z0-9_-]*\):.*/\1/'
    }

    # Remove invalid entries from plugins.load.paths in config
    _fix_invalid_paths() {
        local config_file="$HOME/.openclaw/openclaw.json"
        [ -f "$config_file" ] || return 0
        command -v jq >/dev/null 2>&1 || {
            log_warn "jq not available; cannot auto-fix plugins.load.paths"
            return 1
        }

        local paths
        paths=$(jq -r '.plugins.load.paths[]? // empty' "$config_file" 2>/dev/null)
        [ -n "$paths" ] || return 0

        local removed=0
        local valid_json="[]"
        for path in $paths; do
            expanded="${path/#\~/$HOME}"
            expanded="${expanded/\$HOME/$HOME}"
            if [ -d "$expanded" ]; then
                valid_json=$(printf '%s' "$valid_json" | jq --arg p "$path" '. + [$p]')
            else
                log_warn "Removing invalid path: $path"
                removed=$((removed + 1))
            fi
        done

        [ "$removed" -eq 0 ] && return 0

        local tmp
        tmp=$(mktemp)
        if jq --argjson v "$valid_json" '.plugins.load.paths = $v' "$config_file" > "$tmp"; then
            mv "$tmp" "$config_file"
            printf "   [OK] Removed %d invalid plugin path(s) from config\n" "$removed"
            return 0
        fi
        rm -f "$tmp"
        return 1
    }

    execute() {
        log_info "Starting plugin SDK repair..."

        local doc="${CLAWICU_DOCTOR_OUT:-}"
        local repaired=0

        # --- Case 1: ERR_MODULE_NOT_FOUND for plugin-sdk ---
        if [ -f "$doc" ] && grep -q "Cannot find module.*plugin-sdk\|ERR_MODULE_NOT_FOUND.*plugin-sdk" "$doc" 2>/dev/null; then
            printf "   [*] Detected: plugin-sdk module missing\n"
            local broken_path
            broken_path="$(_find_sdk_plugin_path)"
            if [ -n "$broken_path" ]; then
                local plugin_dir
                plugin_dir="$(dirname "$broken_path")"
                # Walk up to find the directory with package.json
                while [ -n "$plugin_dir" ] && [ "$plugin_dir" != "/" ]; do
                    [ -f "$plugin_dir/package.json" ] && break
                    plugin_dir="$(dirname "$plugin_dir")"
                done
                if [ -f "$plugin_dir/package.json" ]; then
                    printf "   [*] Running npm install in: %s\n" "$plugin_dir"
                    if (cd "$plugin_dir" && npm install --prefer-offline 2>/dev/null); then
                        printf "   [OK] npm install succeeded\n"
                        repaired=$((repaired + 1))
                    else
                        printf "   [!] npm install failed - disabling plugin instead\n"
                        if mv "$broken_path" "${broken_path}.clawicu-disabled" 2>/dev/null; then
                            printf "   [OK] Plugin disabled: %s\n" "$broken_path"
                            repaired=$((repaired + 1))
                        fi
                    fi
                fi
            fi
        fi

        # --- Case 2: api.config.get / API incompatibility ---
        if [ -f "$doc" ] && grep -q "api\.config\.get is not a function\|TypeError:.*is not a function\|ReferenceError:" "$doc" 2>/dev/null; then
            printf "   [*] Detected: plugin API incompatibility (api.config.get)\n"
            local broken_path broken_id
            broken_path="$(_find_api_broken_path)"
            broken_id="$(_find_api_broken_id)"

            if [ -n "$broken_path" ] && [ -f "$broken_path" ]; then
                if mv "$broken_path" "${broken_path}.clawicu-disabled" 2>/dev/null; then
                    printf "   [OK] Plugin disabled: %s\n" "$broken_path"
                    printf "   [i]  Restore: mv \"%s.clawicu-disabled\" \"%s\"\n" "$broken_path" "$broken_path"
                    repaired=$((repaired + 1))
                fi
            fi

            # Also add to plugins.deny if we have an ID
            if [ -n "$broken_id" ] && command -v openclaw >/dev/null 2>&1; then
                openclaw config set "plugins.deny" "[\"${broken_id}\"]" 2>/dev/null && \
                    printf "   [OK] Added '%s' to plugins.deny\n" "$broken_id" || true
            fi
        fi

        # --- Case 3: Invalid plugins.load.paths ---
        if _fix_invalid_paths; then
            repaired=$((repaired + 1))
        fi

        if [ "$repaired" -eq 0 ]; then
            log_warn "Could not automatically repair plugin SDK issues"
            printf "   [!] Manual steps:\n"
            printf "       1. Run: openclaw update\n"
            printf "       2. Or disable the broken plugin manually\n"
            return 1
        fi

        # Verify
        local verify="$CLAWICU_TMPDIR/doctor-verify-sdk.txt"
        openclaw doctor > "$verify" 2>&1 || true
        if ! grep -q "api\.config\.get is not a function\|ERR_MODULE_NOT_FOUND.*plugin-sdk" "$verify" 2>/dev/null; then
            printf "   [OK] Verification passed\n"
        fi

        return 0
    }
}

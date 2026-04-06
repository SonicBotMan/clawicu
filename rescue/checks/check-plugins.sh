# check-plugins.sh - Detect broken or API-incompatible plugins

check_plugins() {
    SEVERITY="fatal"

    local doctor_out="${CLAWICU_DOCTOR_OUT:-}"
    local ext_dir="$HOME/.openclaw/extensions"
    local broken_plugin=""
    local broken_reason=""

    # --- 1. Parse openclaw doctor output for runtime plugin errors ---
    if [ -f "$doctor_out" ]; then
        # Unhandled promise rejection (most critical - plugin crash)
        if grep -q "Unhandled promise rejection" "$doctor_out" 2>/dev/null; then
            # Extract the TypeError message
            local type_err
            type_err="$(grep "TypeError:\|ReferenceError:\|SyntaxError:" "$doctor_out" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')"
            # Extract the plugin file path from "at activate (/path/to/file.js:LINE:COL)"
            local plugin_path
            plugin_path="$(grep "at activate" "$doctor_out" 2>/dev/null | head -1 \
                | grep -o '(/[^)]*)' | tr -d '()' | sed 's/:[0-9]*:[0-9]*$//')"
            # Extract plugin ID: "│  - WARN workflow-orchestration: plugin register..."
            broken_plugin="$(grep "plugin register returned a promise\|async registration is ignored" \
                "$doctor_out" 2>/dev/null | head -1 \
                | sed 's/.*WARN[[:space:]]*\([a-zA-Z0-9_-]*\):.*/\1/')"
            if [ -z "$broken_plugin" ] && [ -n "$plugin_path" ]; then
                broken_plugin="$(echo "$plugin_path" | grep -o 'openclaw-plugin\|[^/]*/dist-node' | head -1)"
            fi
            broken_reason="${type_err:-plugin threw unhandled exception on activate}"
            MESSAGE="Plugin runtime crash: ${broken_reason}"
            DETAILS="Path: ${plugin_path:-unknown}. Plugin ID: ${broken_plugin:-unknown}. Repair will disable this plugin."
            return 0
        fi

        # api.config.get / is not a function style API compatibility errors
        if grep -q "is not a function\|is not defined\|Cannot read propert" "$doctor_out" 2>/dev/null; then
            local api_err
            api_err="$(grep "is not a function\|is not defined\|Cannot read propert" "$doctor_out" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')"
            MESSAGE="Plugin API compatibility error: ${api_err}"
            DETAILS="A plugin is using a deprecated OpenClaw API. Repair will disable the offending plugin."
            return 0
        fi

        # plugin register returned a promise (ignored async registration)
        if grep -q "plugin register returned a promise" "$doctor_out" 2>/dev/null; then
            local async_plugin
            async_plugin="$(grep "plugin register returned a promise" "$doctor_out" 2>/dev/null | awk 'NR==1{print $2}' | tr -d ':')"
            SEVERITY="warn"
            MESSAGE="Plugin '${async_plugin:-unknown}' uses async registration (ignored by OpenClaw)"
            DETAILS="Async plugin.register() calls are silently dropped. Plugin may not work correctly."
            return 0
        fi

        # api.config.get / is not a function (without Unhandled rejection wrapper)
        if grep -q "is not a function\|is not defined\|Cannot read propert" "$doctor_out" 2>/dev/null; then
            local api_err
            api_err="$(grep "is not a function\|is not defined\|Cannot read propert" \
                "$doctor_out" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//')"
            MESSAGE="Plugin API compatibility error: ${api_err}"
            DETAILS="A plugin is using a deprecated OpenClaw API. Repair will disable the offending plugin."
            return 0
        fi

        # plugins.allow is empty warning
        if grep -q "plugins.allow is empty" "$doctor_out" 2>/dev/null; then
            SEVERITY="warn"
            MESSAGE="plugins.allow is empty - all discovered plugins auto-load (security risk)"
            DETAILS="Set plugins.allow to explicit trusted plugin IDs to prevent untrusted plugins from loading."
            return 0
        fi
    fi

    # --- 2. Check extensions directory for structural problems ---
    if [ -d "$ext_dir" ]; then
        local broken_ext=""
        for plugin_dir in "$ext_dir"/*/; do
            [ -d "$plugin_dir" ] || continue
            local name
            name="$(basename "$plugin_dir")"
            # Must have at least one of: index.js, dist/index.js, package.json
            if [ ! -f "$plugin_dir/package.json" ] && \
               [ ! -f "$plugin_dir/index.js" ]     && \
               [ ! -f "$plugin_dir/dist/index.js" ]; then
                broken_ext="$broken_ext $name"
            fi
        done
        if [ -n "$broken_ext" ]; then
            SEVERITY="warn"
            MESSAGE="Extensions missing entry points:${broken_ext}"
            DETAILS="These extension directories have no package.json or index.js: ${broken_ext}"
            return 0
        fi
    fi

    return 1  # No issues found
}

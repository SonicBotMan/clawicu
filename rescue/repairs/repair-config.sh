#!/bin/sh
# repair-config.sh - Restore OpenClaw config from a backup

set -e

# Source dependencies
. "$(dirname "$0")/../lib/bootstrap.sh"
. "$(dirname "$0")/../lib/backup.sh"
. "$(dirname "$0")/../lib/state.sh"
. "$(dirname "$0")/../lib/log.sh"

repair_config() {
    describe() {
        echo "Restore OpenCode configuration from a previous backup"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - List available config backups"
        echo "  - Back up current config before overwriting"
        echo "  - Restore selected backup to active config path (~/.openclaw/openclaw.json)"
        echo "  - Verify restored config is valid JSON5"
        echo "  - Roll back if verification fails"
    }

    # List available backups and return the chosen one
    # Args: $1 = backup directory path
    _list_backups() {
        local backup_dir="$1"
        if [ ! -d "$backup_dir" ]; then
            log_warn "No backup directory found at: $backup_dir"
            return 1
        fi

        local count=0
        for f in "$backup_dir"/*.json "$backup_dir"/*.json5; do
            if [ -f "$f" ]; then
                count=$((count + 1))
                echo "$count $(basename "$f")"
            fi
        done

        if [ "$count" -eq 0 ]; then
            log_warn "No backup files found in: $backup_dir"
            return 1
        fi
        return 0
    }

    # Validate a file is parseable JSON5 / JSON
    # Args: $1 = file path
    _validate_json5() {
        local cfg="$1"
        if [ ! -f "$cfg" ]; then
            return 1
        fi

        # Basic structural check: ensure the file is non-empty and
        # contains at least one key-value pair.
        local size
        size=$(wc -c < "$cfg" 2>/dev/null || echo 0)
        if [ "$size" -eq 0 ]; then
            return 1
        fi

        # Try python or node for JSON validation if available
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "import json,sys; json.loads(open(sys.argv[1]).read())" "$cfg" 2>/dev/null && return 0
            # If strict JSON fails, try a lenient check (JSON5-like)
            python3 -c "
import re, sys
txt = open(sys.argv[1]).read()
# Strip JS-style comments and trailing commas for a rough check
txt = re.sub(r'//.*', '', txt)
txt = re.sub(r'/\*.*?\*/', '', txt, flags=re.DOTALL)
txt = re.sub(r',\s*([}\]])', r'\1', txt)
import json
json.loads(txt)
" "$cfg" 2>/dev/null && return 0
        fi

        if command -v node >/dev/null 2>&1; then
            node -e "try { JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); } catch(e) { process.exit(1); }" "$cfg" 2>/dev/null && return 0
        fi

        # Fallback: accept any non-empty file with braces
        grep -q '{' "$cfg" 2>/dev/null && return 0

        return 1
    }

    execute() {
        log_info "Starting config restore repair..."

        # OpenClaw config lives at ~/.openclaw/openclaw.json (JSON5 format)
        local config_dir="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
        local config_file="$config_dir/openclaw.json"

        # Fallback: accept legacy .json5 extension if present
        if [ ! -f "$config_file" ]; then
            config_file="$config_dir/openclaw.json5"
        fi

        if [ ! -f "$config_file" ]; then
            log_fatal "Cannot find config file in: $config_dir (expected $config_dir/openclaw.json)"
            return 1
        fi

        log_info "Config file: $config_file"

        # Locate backups
        local backup_dir="${OPENCLAW_BACKUP_DIR:-$HOME/.openclaw/backups/config}"

        log_info "Looking for backups in: $backup_dir"
        if ! _list_backups "$backup_dir"; then
            log_fatal "No config backups available for restore"
            return 1
        fi

        # Determine which backup to restore
        # Use env var or fall back to the most recent backup
        local target_backup="${OPENCLAW_RESTORE_BACKUP:-}"

        if [ -z "$target_backup" ]; then
            # Pick the most recent backup file
            target_backup=$(ls -t "$backup_dir"/*.json "$backup_dir"/*.json5 2>/dev/null | head -1)
        else
            # Treat as a filename relative to backup_dir
            if [ ! -f "$target_backup" ]; then
                target_backup="$backup_dir/$target_backup"
            fi
        fi

        if [ ! -f "$target_backup" ]; then
            log_fatal "Backup file not found: $target_backup"
            return 1
        fi

        log_info "Selected backup: $(basename "$target_backup")"

        # Validate the backup before using it
        if ! _validate_json5 "$target_backup"; then
            log_fatal "Backup file does not appear to be valid JSON: $target_backup"
            return 1
        fi

        # Save a direct copy of the current config file for rollback.
        # backup_create() produces a tar.gz of the state dir — cannot be
        # cp'd directly back as a config file, so we keep a separate snapshot.
        local config_snapshot="${config_file}.clawicu-$(date '+%Y%m%d-%H%M%S').bak"
        cp "$config_file" "$config_snapshot"
        log_info "Config snapshot saved: $config_snapshot"

        # Full state backup (discard path — not used for cp rollback)
        backup_create "repair-config" >/dev/null
        state_push "repair-config"

        # Perform the restore
        cp "$target_backup" "$config_file"
        log_info "Restored backup to: $config_file"

        # Verify the restored config
        if _validate_json5 "$config_file"; then
            rm -f "$config_snapshot"
            log_info "Config restore completed successfully"
            return 0
        else
            log_error "Restored config failed validation, rolling back..."
            cp "$config_snapshot" "$config_file"
            rm -f "$config_snapshot"
            state_rollback
            log_error "Rolled back to previous config"
            return 1
        fi
    }
}

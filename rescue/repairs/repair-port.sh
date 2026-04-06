#!/bin/sh
# repair-port.sh - Free port 18789 or reconfigure gateway port

set -e

# Source dependencies
. "$(dirname "$0")/../lib/bootstrap.sh"
. "$(dirname "$0")/../lib/backup.sh"
. "$(dirname "$0")/../lib/state.sh"
. "$(dirname "$0")/../lib/log.sh"

repair_port() {
    describe() {
        echo "Free port 18789 or reconfigure OpenClaw to use a different port"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Detect what process is using port 18789"
        echo "  - Offer to kill the conflicting process (with confirmation)"
        echo "  - Or change OpenClaw gateway port in config"
        echo "  - Verify the chosen port is free after repair"
    }

    # Default OpenClaw gateway port
    _default_port() {
        echo "18789"
    }

    # Detect what's using a given port
    # Args: $1 = port number
    # Outputs: PID and process info
    _detect_port_user() {
        local port="$1"

        # Try lsof first (macOS and Linux)
        if command -v lsof >/dev/null 2>&1; then
            local result
            result=$(lsof -i ":$port" -t 2>/dev/null || true)
            if [ -n "$result" ]; then
                echo "$result"
                return 0
            fi
        fi

        # Try ss (Linux)
        if command -v ss >/dev/null 2>&1; then
            local result
            result=$(ss -tlnp "sport = :$port" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1 || true)
            if [ -n "$result" ]; then
                echo "$result"
                return 0
            fi
        fi

        # Try netstat
        if command -v netstat >/dev/null 2>&1; then
            local result
            result=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d/ -f1 | head -1 || true)
            if [ -n "$result" ]; then
                echo "$result"
                return 0
            fi
        fi

        return 1
    }

    # Get process info for a PID
    # Args: $1 = PID
    _process_info() {
        local pid="$1"
        ps -p "$pid" -o pid,comm 2>/dev/null || echo "PID $pid (unknown process)"
    }

    # Kill a process by PID with user confirmation
    # Args: $1 = PID
    _kill_process() {
        local pid="$1"

        local info
        info=$(_process_info "$pid")
        log_info "Process using port: $info"

        printf "Kill this process? [y/N]: " >&2
        read -r answer

        case "$answer" in
            [yY]|[yY][eE][sS])
                kill "$pid" 2>/dev/null || true
                sleep 2

                # Check if still running
                if kill -0 "$pid" 2>/dev/null; then
                    log_warn "Process did not stop gracefully, force killing..."
                    kill -9 "$pid" 2>/dev/null || true
                    sleep 1
                fi

                if kill -0 "$pid" 2>/dev/null; then
                    log_fatal "Failed to kill process $pid"
                    return 1
                fi

                log_info "Process $pid terminated"
                return 0
                ;;
            *)
                log_info "Skipped killing process"
                return 1
                ;;
        esac
    }

    # Change the gateway port in config
    # OpenClaw config: ~/.openclaw/openclaw.json (JSON5, unquoted keys)
    # Port lives at: gateway: { port: 18789 }
    # Args: $1 = new port number
    _change_config_port() {
        local new_port="$1"
        # OpenClaw config is always at ~/.openclaw/openclaw.json
        local config_dir="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
        local config_file=""

        for f in "$config_dir/openclaw.json" "$config_dir/openclaw.json5"; do
            if [ -f "$f" ]; then
                config_file="$f"
                break
            fi
        done

        if [ -z "$config_file" ]; then
            # If config file doesn't exist yet, use 'openclaw config set' to create it
            if command -v openclaw >/dev/null 2>&1; then
                log_info "No config file found; using 'openclaw config set' to create entry"
                openclaw config set gateway.port "$new_port" 2>/dev/null && return 0
            fi
            log_warn "No config file found to update"
            return 1
        fi

        log_info "Updating port in: $config_file"

        # Preferred: delegate to the official CLI which handles JSON5 correctly
        if command -v openclaw >/dev/null 2>&1; then
            openclaw config set gateway.port "$new_port" 2>/dev/null && {
                log_info "Port set to $new_port via openclaw config set"
                return 0
            }
        fi

        local old_port
        old_port=$(_default_port)

        # Fallback: sed-based substitution using a temp file (avoids BSD sed -i issues).
        # OpenClaw JSON5 uses unquoted key: gateway: { port: 18789 }
        # Also handle quoted form for safety: "port": 18789
        if command -v sed >/dev/null 2>&1; then
            local tmp
            tmp="$(mktemp)"
            sed "s/port:[[:space:]]*$old_port/port: $new_port/g" "$config_file" \
                | sed "s/\"port\"[[:space:]]*:[[:space:]]*$old_port/\"port\": $new_port/g" > "$tmp" \
                && mv "$tmp" "$config_file" || { rm -f "$tmp"; return 1; }
            log_info "Port changed from $old_port to $new_port"
            return 0
        fi

        return 1
    }

    # Check if a port is free
    # Args: $1 = port number
    _port_is_free() {
        local port="$1"
        local pid
        pid=$(_detect_port_user "$port") || true
        [ -z "$pid" ]
    }

    execute() {
        log_info "Starting port repair..."

        local target_port="${OPENCLAW_PORT:-$(_default_port)}"
        log_info "Checking port: $target_port"

        # Check if port is already free
        if _port_is_free "$target_port"; then
            log_info "Port $target_port is already free"
            return 0
        fi

        local pid
        pid=$(_detect_port_user "$target_port")
        log_warn "Port $target_port is in use by PID $pid"

        backup_create "repair-port"
        state_push "repair-port"

        # Ask user what to do
        echo "" >&2
        echo "Options:" >&2
        echo "  1) Kill the process using port $target_port" >&2
        echo "  2) Change OpenClaw gateway to a different port" >&2
        echo "  3) Cancel" >&2
        printf "Choose [1/2/3]: " >&2

        read -r choice

        case "$choice" in
            1)
                if _kill_process "$pid"; then
                    if _port_is_free "$target_port"; then
                        log_info "Port $target_port is now free"
                        return 0
                    else
                        log_warn "Port $target_port is still in use"
                        return 1
                    fi
                else
                    return 1
                fi
                ;;
            2)
                printf "Enter new port number: " >&2
                read -r new_port

                if [ -z "$new_port" ]; then
                    log_fatal "No port specified"
                    return 1
                fi

                # Validate port number
                case "$new_port" in
                    *[!0-9]*)
                        log_fatal "Invalid port number: $new_port"
                        return 1
                        ;;
                esac

                if [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
                    log_fatal "Port must be between 1 and 65535"
                    return 1
                fi

                if ! _port_is_free "$new_port"; then
                    log_fatal "Port $new_port is also in use"
                    return 1
                fi

                if _change_config_port "$new_port"; then
                    log_info "Gateway port changed to $new_port"
                    return 0
                else
                    log_fatal "Failed to update config"
                    return 1
                fi
                ;;
            3)
                log_info "Cancelled by user"
                return 1
                ;;
            *)
                log_warn "Invalid choice"
                return 1
                ;;
        esac
    }
}

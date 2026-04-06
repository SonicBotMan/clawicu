#!/bin/sh
# repair-gateway.sh - Restart the OpenClaw gateway process

set -e

. "$(dirname "$0")/../lib/bootstrap.sh"
. "$(dirname "$0")/../lib/backup.sh"
. "$(dirname "$0")/../lib/state.sh"
. "$(dirname "$0")/../lib/log.sh"

repair_gateway() {
    _gateway_port="${OPENCLAW_GATEWAY_PORT:-18789}"

    describe() {
        echo "Restart the OpenClaw gateway, auto-detecting install method"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Detect install method (npm / Docker / Podman)"
        echo "  - Record current gateway PID for rollback"
        echo "  - Kill existing gateway process"
        echo "  - Restart gateway via detected method"
        echo "  - Wait for gateway to respond on port $_gateway_port"
        echo "  - Roll back (best-effort fresh start) if restart fails"
    }

    _detect_install_method() {
        # openclaw is the binary for all npm install paths
        if command -v openclaw >/dev/null 2>&1; then
            echo "npm"
            return 0
        fi
        if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' 2>/dev/null | grep -q openclaw; then
            echo "docker"
            return 0
        fi
        if command -v podman >/dev/null 2>&1 && podman ps --format '{{.Names}}' 2>/dev/null | grep -q openclaw; then
            echo "podman"
            return 0
        fi
        return 1
    }

    _find_gateway_pid() {
        local pid
        pid=$(lsof -ti :"$_gateway_port" 2>/dev/null | head -1)
        if [ -n "$pid" ]; then
            echo "$pid"
            return 0
        fi
        # Match the openclaw process (gateway runs as 'openclaw gateway')
        pid=$(pgrep -f "openclaw" 2>/dev/null | head -1)
        echo "$pid"
        [ -n "$pid" ]
    }

    _kill_gateway() {
        local pid="$1"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            log_info "Sending SIGTERM to gateway PID $pid"
            kill "$pid" 2>/dev/null || true
            local retries=0
            while [ $retries -lt 10 ] && kill -0 "$pid" 2>/dev/null; do
                sleep 1
                retries=$((retries + 1))
            done
            if kill -0 "$pid" 2>/dev/null; then
                log_warn "Gateway did not stop gracefully, sending SIGKILL"
                kill -9 "$pid" 2>/dev/null || true
                sleep 1
            fi
        fi
    }

    _start_gateway_npm() {
        log_info "Starting gateway via openclaw gateway..."
        # 'openclaw gateway' runs the gateway in foreground; background it for repair
        nohup openclaw gateway --port "$_gateway_port" >/dev/null 2>&1 &
    }

    _start_gateway_docker() {
        log_info "Starting gateway via Docker..."
        # Docker Compose service is named 'openclaw-gateway'
        # Image: ghcr.io/openclaw/openclaw:latest
        docker start openclaw-gateway 2>/dev/null && return 0
        docker run -d --name openclaw-gateway \
            -p "$_gateway_port:18789" \
            ghcr.io/openclaw/openclaw:latest 2>/dev/null
    }

    _start_gateway_podman() {
        log_info "Starting gateway via Podman..."
        podman start openclaw-gateway 2>/dev/null && return 0
        podman run -d --name openclaw-gateway \
            -p "$_gateway_port:18789" \
            ghcr.io/openclaw/openclaw:latest 2>/dev/null
    }

    _wait_for_gateway() {
        local max_wait="${OPENCLAW_GATEWAY_TIMEOUT:-30}"
        local elapsed=0
        log_info "Waiting for gateway to respond on port $_gateway_port (timeout: ${max_wait}s)..."
        while [ $elapsed -lt $max_wait ]; do
            # /healthz is the standard liveness endpoint (not /health)
            if curl -sf "http://127.0.0.1:$_gateway_port/healthz" >/dev/null 2>&1; then
                return 0
            fi
            if nc -z 127.0.0.1 "$_gateway_port" 2>/dev/null; then
                return 0
            fi
            sleep 1
            elapsed=$((elapsed + 1))
        done
        return 1
    }

    execute() {
        log_info "Starting gateway restart repair..."

        local method
        if ! method=$(_detect_install_method); then
            log_fatal "Cannot detect gateway install method. Install via npm, Docker, or Podman."
            return 1
        fi
        log_info "Detected install method: $method"

        local old_pid
        old_pid=$(_find_gateway_pid || echo "")
        if [ -n "$old_pid" ]; then
            log_info "Found existing gateway PID: $old_pid"
        else
            log_warn "No running gateway process detected"
        fi

        state_push "repair-gateway"
        backup_create "repair-gateway" >/dev/null

        if [ -n "$old_pid" ]; then
            _kill_gateway "$old_pid"
            log_info "Previous gateway process stopped"
        fi

        case "$method" in
            npm)    _start_gateway_npm ;;
            docker) _start_gateway_docker ;;
            podman) _start_gateway_podman ;;
        esac

        if _wait_for_gateway; then
            log_info "Gateway restart completed successfully on port $_gateway_port"
            return 0
        else
            log_error "Gateway did not come up within timeout"
            # Note: the original process was already killed; we cannot restore
            # it by PID. Attempt a fresh start as best-effort recovery.
            if [ -n "$old_pid" ]; then
                log_info "Attempting recovery: starting a fresh gateway instance..."
                case "$method" in
                    npm)    _start_gateway_npm ;;
                    docker) _start_gateway_docker ;;
                    podman) _start_gateway_podman ;;
                esac
                sleep 3
                if _wait_for_gateway; then
                    log_warn "Gateway recovered (note: original PID $old_pid could not be restored)"
                    return 0
                fi
            fi
            state_rollback
            log_error "Gateway restart failed; original process (PID ${old_pid:-none}) was stopped and could not be recovered"
            return 1
        fi
    }
}

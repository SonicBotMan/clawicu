#!/bin/sh
# repair-daemon.sh - Reinstall launchd (macOS) or systemd user service (Linux)
#
# OpenClaw installs a user-level daemon via 'openclaw daemon install':
#   macOS:  LaunchAgent plist under ~/Library/LaunchAgents/
#   Linux:  systemd user service (~/.config/systemd/user/) — NO root required
#
# This repair script uses 'openclaw daemon' subcommands to reinstall the service
# correctly, rather than generating plist/unit files manually.

set -e

. "$(dirname "$0")/../lib/bootstrap.sh"
. "$(dirname "$0")/../lib/backup.sh"
. "$(dirname "$0")/../lib/state.sh"
. "$(dirname "$0")/../lib/log.sh"

repair_daemon() {
    _gateway_port="${OPENCLAW_GATEWAY_PORT:-18789}"

    describe() {
        echo "Reinstall the OpenClaw gateway as a system service (launchd or systemd)"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Detect OS (macOS → launchd LaunchAgent, Linux → systemd user service)"
        echo "  - Locate the openclaw binary"
        echo "  - Stop and uninstall any existing service"
        echo "  - Run 'openclaw daemon install' to install fresh service"
        echo "  - Run 'openclaw daemon start' to start the service"
        echo "  - Verify service is running via 'openclaw daemon status'"
        echo "  - Roll back (attempt uninstall) if service fails to start"
    }

    _detect_os() {
        local uname_out
        uname_out="$(uname -s)"
        case "$uname_out" in
            Darwin) echo "macos" ;;
            Linux)  echo "linux" ;;
            *)      echo "unknown" ;;
        esac
    }

    _find_gateway_binary() {
        if command -v openclaw >/dev/null 2>&1; then
            command -v openclaw
            return 0
        fi
        local candidate
        for candidate in \
            /usr/local/bin/openclaw \
            /opt/homebrew/bin/openclaw \
            "$HOME/.local/bin/openclaw" \
            "$HOME/.openclaw/bin/openclaw" \
            /usr/bin/openclaw; do
            if [ -x "$candidate" ]; then
                echo "$candidate"
                return 0
            fi
        done
        return 1
    }

    _service_is_running() {
        local os="$1"
        if [ "$os" = "macos" ]; then
            # 'openclaw daemon status' exits 0 when running
            openclaw daemon status 2>/dev/null | grep -qi "running\|active" && return 0
        else
            # systemd user service
            openclaw daemon status 2>/dev/null | grep -qi "running\|active" && return 0
        fi
        return 1
    }

    _install_service() {
        local os="$1"
        log_info "Installing gateway service via 'openclaw daemon install'..."

        # --force overwrites an existing service registration
        if [ -n "$_gateway_port" ] && [ "$_gateway_port" != "18789" ]; then
            openclaw daemon install --force --port "$_gateway_port" 2>/dev/null
        else
            openclaw daemon install --force 2>/dev/null
        fi

        sleep 2

        log_info "Starting gateway service via 'openclaw daemon start'..."
        openclaw daemon start 2>/dev/null || true

        sleep 3

        if _service_is_running "$os"; then
            return 0
        fi
        return 1
    }

    _uninstall_service() {
        log_info "Uninstalling existing service (best-effort)..."
        openclaw daemon stop 2>/dev/null || true
        openclaw daemon uninstall 2>/dev/null || true
    }

    execute() {
        log_info "Starting daemon reinstall repair..."

        local os
        os=$(_detect_os)
        if [ "$os" = "unknown" ]; then
            log_fatal "Unsupported operating system. Only macOS and Linux are supported."
            return 1
        fi
        log_info "Detected OS: $os"

        local gateway_bin
        if ! gateway_bin=$(_find_gateway_binary); then
            log_fatal "Cannot locate openclaw binary. Ensure it is installed and in PATH."
            return 1
        fi
        log_info "Gateway binary: $gateway_bin"

        state_push "repair-daemon"
        backup_create "repair-daemon" >/dev/null

        # Stop and uninstall any broken/existing registration before reinstalling
        _uninstall_service

        if _install_service "$os"; then
            log_info "Daemon service installed and started successfully"
            return 0
        else
            log_error "Daemon service failed to start, attempting rollback..."
            _uninstall_service
            state_rollback
            log_error "Rollback completed. You may need to manually run: openclaw daemon install"
            return 1
        fi
    }
}

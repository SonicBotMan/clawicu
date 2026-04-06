#!/bin/sh
# repair-daemon.sh - Reinstall launchd (macOS) or systemd user service (Linux)
#
# OpenClaw installs a user-level daemon via 'openclaw daemon install':
#   macOS:  LaunchAgent plist under ~/Library/LaunchAgents/
#   Linux:  systemd user service (~/.config/systemd/user/) - NO root required
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
        echo "  - Detect OS (macOS -> launchd LaunchAgent, Linux -> systemd user service)"
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
        # Redirect stdout to /dev/null to suppress plugin loading noise;
        # grep operates on the piped output so this still works correctly.
        openclaw daemon status >/dev/null 2>&1 && return 0
        # Fallback: check via systemctl (Linux) or launchctl (macOS)
        if command -v systemctl >/dev/null 2>&1; then
            systemctl --user is-active openclaw-gateway >/dev/null 2>&1 && return 0
        fi
        if command -v launchctl >/dev/null 2>&1; then
            launchctl list 2>/dev/null | grep -q "openclaw" && return 0
        fi
        return 1
    }

    _install_service() {
        local os="$1"
        log_info "Installing gateway service via 'openclaw daemon install'..."

        # Redirect ALL output (stdout+stderr) to suppress plugin loading noise
        if [ -n "$_gateway_port" ] && [ "$_gateway_port" != "18789" ]; then
            openclaw daemon install --force --port "$_gateway_port" >/dev/null 2>&1
        else
            openclaw daemon install --force >/dev/null 2>&1
        fi

        sleep 2

        log_info "Starting gateway service via 'openclaw daemon start'..."
        openclaw daemon start >/dev/null 2>&1 || true

        sleep 3

        if _service_is_running "$os"; then
            return 0
        fi
        return 1
    }

    _uninstall_service() {
        log_info "Uninstalling existing service (best-effort)..."
        # Redirect ALL output to suppress plugin loading noise from openclaw
        openclaw daemon stop    >/dev/null 2>&1 || true
        openclaw daemon uninstall >/dev/null 2>&1 || true
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

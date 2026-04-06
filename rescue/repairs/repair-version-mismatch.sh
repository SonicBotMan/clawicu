# repair-version-mismatch.sh - Restart Gateway to resolve CLI/Gateway version mismatch

repair_version_mismatch() {
    describe() {
        echo "Restart OpenClaw Gateway to match the currently installed CLI version"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Detect how the gateway was started (systemd, launchd, direct process)"
        echo "  - Restart the gateway service"
        echo "  - Verify the version mismatch is resolved"
    }

    execute() {
        log_info "Starting version mismatch repair (gateway restart)..."

        local restarted=0

        # --- Strategy 1: systemd (Linux user service) ---
        if command -v systemctl >/dev/null 2>&1; then
            if systemctl --user is-active openclaw-gateway >/dev/null 2>&1; then
                printf "   [*] Restarting systemd user service: openclaw-gateway\n"
                if systemctl --user restart openclaw-gateway 2>/dev/null; then
                    printf "   [OK] Gateway restarted via systemd\n"
                    restarted=1
                else
                    log_warn "systemctl restart failed"
                fi
            fi
        fi

        # --- Strategy 2: launchd (macOS) ---
        if [ "$restarted" -eq 0 ] && command -v launchctl >/dev/null 2>&1; then
            local plist_label
            plist_label=$(launchctl list 2>/dev/null | grep "openclaw" | awk '{print $3}' | head -1)
            if [ -n "$plist_label" ]; then
                printf "   [*] Restarting launchd service: %s\n" "$plist_label"
                if launchctl kickstart -k "gui/$(id -u)/$plist_label" 2>/dev/null; then
                    printf "   [OK] Gateway restarted via launchd\n"
                    restarted=1
                fi
            fi
        fi

        # --- Strategy 3: openclaw daemon commands ---
        if [ "$restarted" -eq 0 ] && command -v openclaw >/dev/null 2>&1; then
            printf "   [*] Restarting via openclaw daemon stop/start\n"
            openclaw daemon stop 2>/dev/null || true
            sleep 1
            if openclaw daemon start 2>/dev/null; then
                printf "   [OK] Gateway restarted via openclaw daemon\n"
                restarted=1
            fi
        fi

        # --- Strategy 4: kill and restart process directly ---
        if [ "$restarted" -eq 0 ]; then
            local pid
            pid=$(pgrep -f "openclaw.*gateway\|openclaw-gateway" 2>/dev/null | head -1)
            if [ -n "$pid" ]; then
                printf "   [*] Killing gateway process %s and restarting\n" "$pid"
                kill "$pid" 2>/dev/null || true
                sleep 2
                if command -v openclaw >/dev/null 2>&1; then
                    openclaw gateway &
                    sleep 2
                    if pgrep -f "openclaw.*gateway" >/dev/null 2>&1; then
                        printf "   [OK] Gateway process restarted\n"
                        restarted=1
                    fi
                fi
            fi
        fi

        if [ "$restarted" -eq 0 ]; then
            log_warn "Could not automatically restart the gateway"
            printf "   [!] Manual fix: restart your gateway service\n"
            printf "       Linux:  systemctl --user restart openclaw-gateway\n"
            printf "       macOS:  openclaw daemon stop && openclaw daemon start\n"
            return 1
        fi

        # Verify version match after restart (wait a moment for it to settle)
        sleep 2
        local cli_ver gateway_ver
        cli_ver=$(openclaw --version 2>/dev/null | grep -oE '[0-9]{4}\.[0-9]+\.[0-9]+' | head -1)
        gateway_ver=$(curl -sf "http://localhost:18789/healthz" 2>/dev/null | grep -oE '"version":"[^"]*"' | cut -d'"' -f4)

        if [ -n "$cli_ver" ] && [ -n "$gateway_ver" ]; then
            if [ "$cli_ver" = "$gateway_ver" ]; then
                printf "   [OK] Versions now match: CLI=%s Gateway=%s\n" "$cli_ver" "$gateway_ver"
            else
                printf "   [!] Versions still differ: CLI=%s Gateway=%s\n" "$cli_ver" "$gateway_ver"
            fi
        else
            printf "   [i] Could not verify version match (gateway may still be starting up)\n"
        fi

        return 0
    }
}

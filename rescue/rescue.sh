#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAWICU_VERSION="0.2.0"

. "$SCRIPT_DIR/lib/bootstrap.sh"
. "$SCRIPT_DIR/lib/log.sh"
. "$SCRIPT_DIR/lib/ui.sh"
. "$SCRIPT_DIR/lib/backup.sh"
. "$SCRIPT_DIR/lib/state.sh"
. "$SCRIPT_DIR/lib/verify.sh"

bootstrap

DRY_RUN=0
VERBOSE=0
FORCE=0

while getopts "dhvf" opt; do
    case "$opt" in
        d) DRY_RUN=1 ;;
        v) VERBOSE=1; CLAWICU_LOG_LEVEL="DEBUG" ;;
        f) FORCE=1 ;;
        h)
            echo "Usage: $0 [-d] [-v] [-f]"
            echo "  -d  Dry run (show what would be done)"
            echo "  -v  Verbose output"
            echo "  -f  Force (skip confirmations)"
            exit 0
            ;;
    esac
done

phase_0_bootstrap() {
    icu_header "$CLAWICU_VERSION"
    
    printf "   ${C_CYAN}*${C_NC} System: ${C_BOLD}%s${C_NC} | ${C_CYAN}*${C_NC} Arch: ${C_BOLD}%s${C_NC} | ${C_CYAN}*${C_NC} Shell: ${C_BOLD}%s${C_NC}\n" "$CLAWICU_OS" "$CLAWICU_ARCH" "$CLAWICU_SHELL"
    printf "   ${C_CYAN}*${C_NC} Install: ${C_BOLD}%s${C_NC} | ${C_CYAN}*${C_NC} Version: ${C_BOLD}%s${C_NC}\n" "$CLAWICU_INSTALL_METHOD" "$CLAWICU_VERSION"
    printf "   ${C_CYAN}*${C_NC} Docs:    ${C_BOLD}https://xagent.icu/${C_NC}\n"
    printf "\n"
    
    printf "   ${C_DIM}-------------------------------------------------------------${C_NC}\n"
    
    rescue_announce START "Initializing rescue protocol..."
    
    if ! command -v curl >/dev/null 2>&1; then
        printf "\n   ${C_RED}[!!] FATAL: curl is required but not found${C_NC}\n"
        exit 1
    fi
    
    printf "   ${C_GREEN}[OK]${C_NC} curl .............. ${C_GREEN}READY${C_NC}\n"
}

phase_1_doctor() {
    phase_indicator 1 6 "OpenClaw Doctor Check"

    if ! command -v openclaw >/dev/null 2>&1; then
        check_result WARN "OpenClaw Binary" "not found in PATH"
        return 0
    fi

    check_result PROCESSING "OpenClaw Doctor" "running diagnosis..."
    printf "\n"

    # Save output to temp file so check-plugins.sh can reuse it without running doctor twice.
    # Run with a 30s timeout: a broken plugin (e.g. api.config.get crash) can cause
    # 'openclaw doctor' to hang indefinitely. Use 'if' to shield set -e.
    CLAWICU_DOCTOR_OUT="$CLAWICU_TMPDIR/doctor-output.txt"
    local doctor_exit=0

    # Run openclaw doctor in the background and manually wait with a timeout
    # (portable: 'timeout' is not available on all systems/macOS by default)
    OPENCLAW_NO_RESPAWN=1 openclaw doctor > "$CLAWICU_DOCTOR_OUT" 2>&1 &
    local _doc_pid=$!
    local _waited=0
    while kill -0 "$_doc_pid" 2>/dev/null && [ "$_waited" -lt 30 ]; do
        sleep 1
        _waited=$((_waited + 1))
    done
    if kill -0 "$_doc_pid" 2>/dev/null; then
        # Still running after 30s - kill it and note timeout
        kill "$_doc_pid" 2>/dev/null || true
        wait "$_doc_pid" 2>/dev/null || true
        doctor_exit=124
        printf "   ${C_YELLOW}[!]${C_NC} openclaw doctor timed out after 30s (plugin crash suspected)\n"
    else
        wait "$_doc_pid" 2>/dev/null && doctor_exit=0 || doctor_exit=$?
    fi

    # Detect real errors: unhandled promise rejections, TypeError, etc.
    local has_fatal=0
    if grep -q "Unhandled promise rejection\|TypeError:\|ReferenceError:\|SyntaxError:" "$CLAWICU_DOCTOR_OUT" 2>/dev/null; then
        has_fatal=1
    fi

    if [ "$has_fatal" -eq 1 ] || [ "$doctor_exit" -ne 0 ]; then
        check_result WARN "OpenClaw Doctor" "errors detected (see details below)"
        # Show only the error lines, indented
        grep --color=never "Unhandled\|TypeError\|ReferenceError\|SyntaxError\|ERROR\|WARN\|WARNING" \
            "$CLAWICU_DOCTOR_OUT" 2>/dev/null | sed 's/^/   /' | head -20
        printf "\n"
    else
        check_result OK "OpenClaw Doctor" "all checks passed"
    fi
    export CLAWICU_DOCTOR_OUT
    return 0
}

# _do_check: run one check function, record result in RESULTS_FILE.
# $1=fn_name (underscored, e.g. "config_schema")  - matches actual function name
# $2=check_name (hyphenated, e.g. "config-schema") - written to RESULTS_FILE
# $3=index  $4=total
_do_check() {
    local fn_name="$1" check_name="$2" idx="$3" total="$4"
    check_result PROCESSING "[$idx/$total]" "$check_name"
    SEVERITY="" MESSAGE="" DETAILS=""
    local check_tmpfile="$CLAWICU_TMPDIR/check-out-$idx"
    # Use 'if' to shield set -e from the non-zero return of passing checks.
    local check_exit=1
    if "check_${fn_name}" > "$check_tmpfile" 2>&1; then
        check_exit=0
    fi
    rm -f "$check_tmpfile"
    if [ "$check_exit" -eq 0 ]; then
        printf "\r   ${C_YELLOW}[!]${C_NC} %-40s ${C_YELLOW}%s${C_NC}\n" "$check_name" "WARNING"
        echo "WARN:${SEVERITY:-warn}:$check_name:${MESSAGE:-unknown issue}:${DETAILS:-}" >> "$RESULTS_FILE"
    else
        printf "\r   ${C_GREEN}[OK]${C_NC} %-40s ${C_GREEN}OK${C_NC}\n" "$check_name"
        echo "PASS:$check_name" >> "$RESULTS_FILE"
    fi
    sleep 0.1
}

phase_2_checks() {
    phase_indicator 2 6 "Running Diagnostic Checks"

    RESULTS_FILE="$CLAWICU_TMPDIR/check-results.txt"
    > "$RESULTS_FILE"

    local check_count=0

    printf "\n"

    # Bundled mode: _CLAWICU_CHECK_FNS is injected by build-rescue.sh.
    # Dev mode:     _CLAWICU_CHECK_FNS is empty; discover scripts from disk instead.
    if [ -n "${_CLAWICU_CHECK_FNS:-}" ]; then
        local total_checks
        total_checks=$(printf '%s\n' $_CLAWICU_CHECK_FNS | wc -l | tr -d ' ')
        for fn_name in $_CLAWICU_CHECK_FNS; do
            check_count=$((check_count + 1))
            local check_name
            check_name="$(printf '%s' "$fn_name" | tr '_' '-')"
            _do_check "$fn_name" "$check_name" "$check_count" "$total_checks"
        done
    else
        local total_checks
        total_checks=$(ls "$SCRIPT_DIR/checks"/check-*.sh 2>/dev/null | wc -l | tr -d ' ')
        for check in "$SCRIPT_DIR/checks"/check-*.sh; do
            [ -f "$check" ] || continue
            check_count=$((check_count + 1))
            . "$check"
            local check_name fn_name
            check_name="$(basename "$check" .sh)"; check_name="${check_name#check-}"
            fn_name="$(printf '%s' "$check_name" | tr '-' '_')"
            _do_check "$fn_name" "$check_name" "$check_count" "$total_checks"
        done
    fi

    printf "\n"
    printf "   ${C_DIM}-------------------------------------------------------------${C_NC}\n"

    # RESULTS_FILE uses WARN:fatal: for fatal issues and WARN:warn: for warnings.
    # (Nothing writes FAIL: - that was a legacy mismatch with ^FAIL:)
    local fail_count warn_count
    fail_count="$(grep "^WARN:fatal:" "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d " ")"
    warn_count="$(grep "^WARN:warn:\|^WARN:info:" "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d " ")"

    if [ "$fail_count" -gt 0 ] || [ "$warn_count" -gt 0 ]; then
        [ "$fail_count" -gt 0 ] && printf "   ${C_RED}[!!] Issues Found: ${C_BOLD}%s FATAL${C_NC}" "$fail_count"
        [ "$warn_count" -gt 0 ] && printf "   ${C_YELLOW}[!] %s WARNINGS${C_NC}" "$warn_count"
        printf "\n"
    else
        printf "   ${C_GREEN}[OK] All Checks Passed${C_NC}\n"
    fi
}

phase_3_triage() {
    phase_indicator 3 6 "Triage & Analysis"
    
    # Phase 2 writes records as "WARN:<severity>:..." - match that prefix, not "FAIL:".
    FATAL_COUNT="$(grep "^WARN:fatal:" "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d " ")"
    WARN_COUNT="$(grep "^WARN:warn:"  "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d " ")"
    INFO_COUNT="$(grep "^WARN:info:"  "$RESULTS_FILE" 2>/dev/null | wc -l | tr -d " ")"
    
    [ -z "$FATAL_COUNT" ] && FATAL_COUNT=0
    [ -z "$WARN_COUNT" ] && WARN_COUNT=0
    [ -z "$INFO_COUNT" ] && INFO_COUNT=0
    
    printf "\n"
    
    if [ "$FATAL_COUNT" -gt 0 ]; then
        vital_monitor "CRITICAL" "---" "---" "---"
        printf "\n   ${C_RED}* PATIENT IN CRITICAL CONDITION${C_NC}\n"
        printf "   ${C_RED}* IMMEDIATE RESCUE REQUIRED${C_NC}\n"
    elif [ "$WARN_COUNT" -gt 0 ]; then
        vital_monitor "WARNING" "---" "---" "---"
        printf "\n   ${C_YELLOW}* PATIENT REQUIRES ATTENTION${C_NC}\n"
    else
        vital_monitor "STABLE" "72" "98" "36.6"
        printf "\n   ${C_GREEN}* PATIENT STABLE - NO IMMEDIATE ACTION REQUIRED${C_NC}\n"
    fi
}

phase_4_menu() {
    phase_indicator 4 6 "Select Treatment Plan"
    
    if [ "$FATAL_COUNT" -eq 0 ] && [ "$WARN_COUNT" -eq 0 ]; then
        check_result OK "OpenClaw Status" "system is healthy"
        printf "\n"
        rescue_announce COMPLETE "All systems operational"
        return 1
    fi
    
    printf "\n"
    printf "   ${C_BOLD}Issue Analysis:${C_NC}\n"
    printf "\n"
    
    while IFS=: read -r _ severity check msg details; do
        [ -z "$check" ] && continue
        case "$severity" in
            fatal)
                printf "   ${C_RED}[[!!]]${C_NC} ${C_BOLD}FATAL:${C_NC} %s\n" "$msg"
                [ -n "$details" ] && printf "         ${C_DIM}%s${C_NC}\n" "$details"
                ;;
            warn)
                printf "   ${C_YELLOW}[[!]]${C_NC} ${C_BOLD}WARN:${C_NC} %s\n" "$msg"
                ;;
            info)
                printf "   ${C_CYAN}[i]${C_NC} ${C_BOLD}INFO:${C_NC} %s\n" "$msg"
                ;;
        esac
    done < "$RESULTS_FILE"
    
    printf "\n"
    printf "   ${C_BOLD}Available Treatment Plans:${C_NC}\n"
    printf "\n"
    
    local option_num=1
    printf "   ${C_GREEN}[a]${C_NC} Auto-Treatment - Let ICU handle everything\n"
    printf "   ${C_CYAN}[1]${C_NC} Quick Fix - Safe, low-risk repairs only\n"
    printf "   ${C_YELLOW}[2]${C_NC} Full Treatment - Include all repairs\n"
    printf "   ${C_RED}[3]${C_NC} Nuclear Option - Full state reset\n"
    printf "   ${C_DIM}[s]${C_NC} Export Report - Save diagnostic data\n"
    printf "   ${C_DIM}[q]${C_NC} Quit - Exit without changes\n"
    
    printf "\n"
    printf "   ${C_BOLD}Select option [a]:${C_NC} "
    read -r CLAWICU_CHOICE
    
    [ -z "$CLAWICU_CHOICE" ] && CLAWICU_CHOICE="a"
    export CLAWICU_CHOICE
    
    printf "\n"
    
    case "$CLAWICU_CHOICE" in
        a|A)
            rescue_announce ING "Auto-treatment protocol selected..."
            ;;
        1)
            printf "   ${C_CYAN}/${C_NC} Quick-fix mode selected (low-risk repairs only)\n"
            ;;
        2)
            printf "   ${C_YELLOW}/${C_NC} Full-treatment mode selected\n"
            ;;
        3)
            printf "   ${C_RED}/${C_NC} Nuclear option selected - proceeding to Phase 5\n"
            ;;
        s|S)
            local report="$HOME/.openclaw/clawicu-report-$(date '+%Y%m%d-%H%M%S').txt"
            mkdir -p "$(dirname "$report")"
            {
                echo "ClawICU Diagnostic Report"
                echo "========================"
                echo "Date: $(date)"
                echo "System: $CLAWICU_OS $CLAWICU_ARCH"
                echo ""
                cat "$RESULTS_FILE"
            } > "$report"
            printf "   ${C_GREEN}[OK]${C_NC} Report saved: %s\n" "$report"
            CLAWICU_CHOICE="q"
            ;;
        q|Q)
            printf "   ${C_DIM}Exiting without changes...${C_NC}\n"
            exit 0
            ;;
        *)
            printf "   ${C_YELLOW}[!]${C_NC} Invalid option, using auto-treatment...\n"
            CLAWICU_CHOICE="a"
            ;;
    esac
}

# _load_repair: load a repair module so that execute() is defined in current scope.
# Tries file source first (dev mode), then direct function call (bundled mode).
# Returns 0 if the repair module was loaded, 1 if not found.
_load_repair() {
    local repair_fn="$1"   # e.g. "repair_plugins"
    local repair_file="$2" # e.g. "/path/to/repair-plugins.sh" (may not exist)
    if [ -f "$repair_file" ]; then
        . "$repair_file"
        "$repair_fn"   # defines execute() in current scope
        return 0
    fi
    # Bundled mode: function is already defined globally; call it to define execute()
    # 'type' output contains "function" or "shell function" when defined.
    if type "$repair_fn" 2>&1 | grep -q "function"; then
        "$repair_fn"
        return 0
    fi
    return 1
}

phase_5_execute() {
    phase_indicator 5 6 "Executing Repairs"

    local choice="${CLAWICU_CHOICE:-a}"

    case "$choice" in
        q|Q|s|S) return 0 ;;
    esac

    if [ ! -f "$RESULTS_FILE" ]; then
        log_warn "No results file found, skipping repairs"
        return 0
    fi

    printf "\n"

    local repaired=0
    local failed=0
    local skipped=0

    # Nuclear option: bypass per-issue loop and call repair_nuclear directly.
    if [ "$choice" = "3" ]; then
        check_result PROCESSING "Repair" "nuclear-reset"
        local nscript="$SCRIPT_DIR/repairs/repair-nuclear.sh"
        if _load_repair "repair_nuclear" "$nscript"; then
            if execute; then
                check_result OK "Repaired" "nuclear-reset"
                repaired=$((repaired + 1))
            else
                check_result FAIL "Repair Failed" "nuclear-reset"
                failed=$((failed + 1))
            fi
        else
            check_result FAIL "Repair Failed" "nuclear-reset (module missing)"
            failed=$((failed + 1))
        fi
    else
        # For each identified issue, load and run the matching repair module.
        # RESULTS_FILE format: WARN:<severity>:<check_name>:<message>:<details>
        # check_name "plugins" -> repair fn "repair_plugins"
        while IFS=: read -r status severity check_name _msg _details; do
            [ "$status" = "WARN" ] || continue
            [ -z "$check_name" ] && continue

            # In quick-fix mode, skip non-fatal issues
            if [ "$choice" = "1" ] && [ "$severity" != "fatal" ]; then
                skipped=$((skipped + 1))
                continue
            fi

            local repair_fn repair_file
            repair_fn="repair_$(printf '%s' "$check_name" | tr '-' '_')"
            repair_file="$SCRIPT_DIR/repairs/repair-${check_name}.sh"

            check_result PROCESSING "Repairing" "$check_name"

            if _load_repair "$repair_fn" "$repair_file"; then
                if execute; then
                    check_result OK "Repaired" "$check_name"
                    repaired=$((repaired + 1))
                else
                    check_result FAIL "Repair Failed" "$check_name"
                    failed=$((failed + 1))
                fi
            else
                printf "   ${C_DIM}- No repair module for: %s${C_NC}\n" "$check_name"
                skipped=$((skipped + 1))
            fi
        done < "$RESULTS_FILE"
    fi

    printf "\n"
    printf "   ${C_DIM}-------------------------------------------------------------${C_NC}\n"

    [ "$repaired" -gt 0 ] && printf "   ${C_GREEN}[OK]${C_NC} Repaired:  ${C_BOLD}%d${C_NC} module(s)\n" "$repaired"
    [ "$failed"   -gt 0 ] && printf "   ${C_RED}[!!]${C_NC} Failed:    ${C_BOLD}%d${C_NC} module(s)\n" "$failed"
    [ "$skipped"  -gt 0 ] && printf "   ${C_DIM}- Skipped:  %d module(s) (no repair module or filtered by mode)${C_NC}\n" "$skipped"
    printf "\n"
}

phase_6_report() {
    phase_indicator 6 6 "Verification & Report"
    
    local report="$HOME/.openclaw/clawicu-report-$(date '+%Y%m%d-%H%M%S').txt"
    mkdir -p "$(dirname "$report")"
    
    {
        echo "ClawICU Rescue Report"
        echo "===================="
        echo "Date: $(date)"
        echo "System: $CLAWICU_OS $CLAWICU_ARCH $CLAWICU_SHELL"
        echo "Install: $CLAWICU_INSTALL_METHOD"
        echo "Version: $CLAWICU_VERSION"
        echo ""
        echo "Issues Detected:"
        cat "$RESULTS_FILE" 2>/dev/null || echo "  None"
    } > "$report"
    
    printf "\n"
    rescue_announce COMPLETE "Rescue operation finished"
    printf "   ${C_GREEN}[OK]${C_NC} Report: ${C_BOLD}%s${C_NC}\n" "$report"
}

main() {
    # When run as 'curl | sh', the shell's stdin is the pipe (EOF after the
    # script is read). Redirect stdin from /dev/tty so that ALL read commands
    # throughout the script (menu selection, API key input, confirmations)
    # receive keyboard input instead of immediate EOF -> default value.
    if [ ! -t 0 ] && [ -r /dev/tty ]; then
        exec </dev/tty
    fi

    phase_0_bootstrap
    phase_1_doctor || true
    phase_2_checks
    phase_3_triage
    # phase_4_menu returns 1 when the system is healthy (no issues found).
    # In that case, skip repairs but still generate the final report.
    phase_4_menu || { phase_6_report; return 0; }
    phase_5_execute
    phase_6_report
}

main "$@"

#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAWICU_VERSION="0.1.0"

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
    
    printf "   ${C_CYAN}◆${C_NC} System: ${C_BOLD}%s${C_NC} | ${C_CYAN}◆${C_NC} Arch: ${C_BOLD}%s${C_NC} | ${C_CYAN}◆${C_NC} Shell: ${C_BOLD}%s${C_NC}\n" "$CLAWICU_OS" "$CLAWICU_ARCH" "$CLAWICU_SHELL"
    printf "   ${C_CYAN}◆${C_NC} Install: ${C_BOLD}%s${C_NC} | ${C_CYAN}◆${C_NC} Version: ${C_BOLD}%s${C_NC}\n" "$CLAWICU_INSTALL_METHOD" "$CLAWICU_VERSION"
    printf "\n"
    
    printf "   ${C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}\n"
    
    rescue_announce START "Initializing rescue protocol..."
    
    if ! command -v curl >/dev/null 2>&1; then
        printf "\n   ${C_RED}✗ FATAL: curl is required but not found${C_NC}\n"
        exit 1
    fi
    
    printf "   ${C_GREEN}✓${C_NC} curl .............. ${C_GREEN}READY${C_NC}\n"
}

phase_1_doctor() {
    phase_indicator 1 6 "OpenClaw Doctor Check"
    
    if ! command -v openclaw >/dev/null 2>&1; then
        check_result WARN "OpenClaw Binary" "not found in PATH"
        return 0
    fi
    
    check_result PROCESSING "OpenClaw Doctor" "running diagnosis..."
    printf "\n"
    
    local doctor_output
    # Convention: exit 0 = doctor found issues, exit non-zero = all clear
    # Both branches return 0 so main() always continues to Phase 2.
    if doctor_output="$(openclaw doctor 2>&1)"; then
        check_result WARN "OpenClaw Doctor" "reported issues"
        printf "%s\n" "$doctor_output" | sed 's/^/   /'
        printf "\n"
    else
        check_result OK "OpenClaw Doctor" "all checks passed"
    fi
    return 0
}

phase_2_checks() {
    phase_indicator 2 6 "Running Diagnostic Checks"
    
    RESULTS_FILE="$CLAWICU_TMPDIR/check-results.txt"
    > "$RESULTS_FILE"
    
    local check_count=0
    local total_checks=0
    total_checks=$(find "$SCRIPT_DIR/checks" -name "check-*.sh" 2>/dev/null | wc -l | tr -d ' ')
    
    for check in "$SCRIPT_DIR/checks"/check-*.sh; do
        [ -f "$check" ] || continue
        
        check_count=$((check_count + 1))
        . "$check"
        check_name="$(basename "$check" .sh)"
        check_name="${check_name#check-}"
        
        check_result PROCESSING "[$check_count/$total_checks]" "$check_name"
        
        # Reset shared variables before each check so stale values don't bleed through.
        SEVERITY="" MESSAGE="" DETAILS=""
        
        # Run the check function directly (NOT in a subshell via $(...)) so that
        # $SEVERITY / $MESSAGE / $DETAILS set inside the check are visible here.
        # Redirect output to a temp file to keep the display clean.
        local check_tmpfile="$CLAWICU_TMPDIR/check-out-$check_count"
        check_"$check_name" > "$check_tmpfile" 2>&1
        local check_exit=$?
        rm -f "$check_tmpfile"
        
        if [ "$check_exit" -eq 0 ]; then
            # Convention: exit 0 means a problem was found; check sets SEVERITY/MESSAGE/DETAILS
            printf "\r   ${C_YELLOW}⚠${C_NC} %-40s ${C_YELLOW}%s${C_NC}\n" "$check_name" "WARNING"
            echo "WARN:${SEVERITY:-warn}:$check_name:${MESSAGE:-unknown issue}:${DETAILS:-}" >> "$RESULTS_FILE"
        else
            printf "\r   ${C_GREEN}✓${C_NC} %-40s ${C_GREEN}OK${C_NC}\n" "$check_name"
            echo "PASS:$check_name" >> "$RESULTS_FILE"
        fi
        
        sleep 0.1
    done
    
    printf "\n"
    printf "   ${C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}\n"
    
    local fail_count
    fail_count="$(grep -c "^FAIL:" "$RESULTS_FILE" 2>/dev/null || echo 0)"
    local warn_count
    warn_count="$(grep -c "^WARN:" "$RESULTS_FILE" 2>/dev/null || echo 0)"
    
    if [ "$fail_count" -gt 0 ] || [ "$warn_count" -gt 0 ]; then
        printf "   ${C_RED}✗ Issues Found: ${C_BOLD}%s FATAL${C_NC}" "$fail_count"
        [ "$warn_count" -gt 0 ] && printf " | ${C_YELLOW}⚠ %s WARNINGS${C_NC}" "$warn_count"
        printf "\n"
    else
        printf "   ${C_GREEN}✓ All Checks Passed${C_NC}\n"
    fi
}

phase_3_triage() {
    phase_indicator 3 6 "Triage & Analysis"
    
    # Phase 2 writes records as "WARN:<severity>:..." — match that prefix, not "FAIL:".
    FATAL_COUNT="$(grep -c "^WARN:fatal:" "$RESULTS_FILE" 2>/dev/null || echo 0)"
    WARN_COUNT="$(grep -c "^WARN:warn:"  "$RESULTS_FILE" 2>/dev/null || echo 0)"
    INFO_COUNT="$(grep -c "^WARN:info:"  "$RESULTS_FILE" 2>/dev/null || echo 0)"
    
    [ -z "$FATAL_COUNT" ] && FATAL_COUNT=0
    [ -z "$WARN_COUNT" ] && WARN_COUNT=0
    [ -z "$INFO_COUNT" ] && INFO_COUNT=0
    
    printf "\n"
    
    if [ "$FATAL_COUNT" -gt 0 ]; then
        vital_monitor "CRITICAL" "---" "---" "---"
        printf "\n   ${C_RED}● PATIENT IN CRITICAL CONDITION${C_NC}\n"
        printf "   ${C_RED}● IMMEDIATE RESCUE REQUIRED${C_NC}\n"
    elif [ "$WARN_COUNT" -gt 0 ]; then
        vital_monitor "WARNING" "---" "---" "---"
        printf "\n   ${C_YELLOW}● PATIENT REQUIRES ATTENTION${C_NC}\n"
    else
        vital_monitor "STABLE" "72" "98" "36.6"
        printf "\n   ${C_GREEN}● PATIENT STABLE - NO IMMEDIATE ACTION REQUIRED${C_NC}\n"
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
                printf "   ${C_RED}[✗]${C_NC} ${C_BOLD}FATAL:${C_NC} %s\n" "$msg"
                [ -n "$details" ] && printf "         ${C_DIM}%s${C_NC}\n" "$details"
                ;;
            warn)
                printf "   ${C_YELLOW}[⚠]${C_NC} ${C_BOLD}WARN:${C_NC} %s\n" "$msg"
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
    printf "   ${C_GREEN}[a]${C_NC} Auto-Treatment — Let ICU handle everything\n"
    printf "   ${C_CYAN}[1]${C_NC} Quick Fix — Safe, low-risk repairs only\n"
    printf "   ${C_YELLOW}[2]${C_NC} Full Treatment — Include all repairs\n"
    printf "   ${C_RED}[3]${C_NC} Nuclear Option — Full state reset\n"
    printf "   ${C_DIM}[s]${C_NC} Export Report — Save diagnostic data\n"
    printf "   ${C_DIM}[q]${C_NC} Quit — Exit without changes\n"
    
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
            printf "   ${C_CYAN}◐${C_NC} Quick-fix mode selected (low-risk repairs only)\n"
            ;;
        2)
            printf "   ${C_YELLOW}◐${C_NC} Full-treatment mode selected\n"
            ;;
        3)
            printf "   ${C_RED}◐${C_NC} Nuclear option selected — proceeding to Phase 5\n"
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
            printf "   ${C_GREEN}✓${C_NC} Report saved: %s\n" "$report"
            CLAWICU_CHOICE="q"
            ;;
        q|Q)
            printf "   ${C_DIM}Exiting without changes...${C_NC}\n"
            exit 0
            ;;
        *)
            printf "   ${C_YELLOW}⚠${C_NC} Invalid option, using auto-treatment...\n"
            CLAWICU_CHOICE="a"
            ;;
    esac
}

phase_5_execute() {
    phase_indicator 5 6 "Executing Repairs"
    
    local choice="${CLAWICU_CHOICE:-a}"
    
    # Skip if user chose export-only or quit
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
    
    # For nuclear option (choice=3), run repair-nuclear directly instead of per-issue
    if [ "$choice" = "3" ]; then
        local nscript="$SCRIPT_DIR/repairs/repair-nuclear.sh"
        if [ -f "$nscript" ]; then
            check_result PROCESSING "Repair" "nuclear-reset"
            . "$nscript"
            repair_nuclear
            if execute; then
                check_result OK "Repaired" "nuclear-reset"
                repaired=$((repaired + 1))
            else
                check_result FAIL "Repair Failed" "nuclear-reset"
                failed=$((failed + 1))
            fi
        fi
    else
        # For each identified issue, find and run the matching repair module.
        # Results file format: WARN:<severity>:<check_name>:<message>:<details>
        # check_name "config" → repairs/repair-config.sh → function repair_config
        while IFS=: read -r status severity check_name _msg _details; do
            [ "$status" = "WARN" ] || continue
            [ -z "$check_name" ] && continue
            
            local repair_script="$SCRIPT_DIR/repairs/repair-${check_name}.sh"
            
            if [ ! -f "$repair_script" ]; then
                log_debug "No repair module for: $check_name"
                skipped=$((skipped + 1))
                continue
            fi
            
            # In quick-fix mode (choice=1), skip repairs for non-fatal severities
            if [ "$choice" = "1" ] && [ "$severity" != "fatal" ]; then
                log_debug "Skipping non-fatal repair in quick-fix mode: $check_name"
                skipped=$((skipped + 1))
                continue
            fi
            
            check_result PROCESSING "Repairing" "$check_name"
            
            # Source the repair script and call its setup function to define
            # the inner execute() / describe() / dry_run() helpers.
            . "$repair_script"
            local setup_fn
            setup_fn="$(basename "$repair_script" .sh | tr '-' '_')"
            "$setup_fn"   # defines execute(), describe(), etc. in current shell
            
            if execute; then
                check_result OK "Repaired" "$check_name"
                repaired=$((repaired + 1))
            else
                check_result FAIL "Repair Failed" "$check_name"
                failed=$((failed + 1))
            fi
        done < "$RESULTS_FILE"
    fi
    
    printf "\n"
    printf "   ${C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_NC}\n"
    
    [ "$repaired" -gt 0 ] && printf "   ${C_GREEN}✓${C_NC} Repaired:  ${C_BOLD}%d${C_NC} module(s)\n" "$repaired"
    [ "$failed"   -gt 0 ] && printf "   ${C_RED}✗${C_NC} Failed:    ${C_BOLD}%d${C_NC} module(s)\n" "$failed"
    [ "$skipped"  -gt 0 ] && printf "   ${C_DIM}○ Skipped:  %d module(s) (no repair available or filtered by mode)${C_NC}\n" "$skipped"
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
    printf "   ${C_GREEN}✓${C_NC} Report: ${C_BOLD}%s${C_NC}\n" "$report"
}

main() {
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

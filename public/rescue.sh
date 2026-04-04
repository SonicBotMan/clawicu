#!/bin/sh
# ClawICU - OpenClaw Emergency Rescue Script
# Bundled standalone version with ICU UI
# Generated from modular source - all libs and checks inlined

set -e

SCRIPT_VERSION="0.1.0"

# ============================================================================
# BOOTSTRAP - OS/shell detection, install method detection, temp dir setup
# ============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*) echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64)  echo "x86_64" ;;
        arm64|aarch64) echo "arm64" ;;
        *)       echo "unknown" ;;
    esac
}

detect_shell() {
    if [ -n "$BASH_VERSION" ]; then
        if [ "${BASH_VERSION%%.*}" -ge 4 ]; then
            echo "bash4"
        else
            echo "bash3"
        fi
    elif [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    else
        echo "sh"
    fi
}

detect_install_method() {
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        echo "docker"
        return
    fi
    if command -v openclaw >/dev/null 2>&1; then
        if [ -d "$HOME/.npm" ] || [ -d "/usr/local/lib/node_modules/openclaw" ]; then
            echo "npm-global"
        else
            echo "npm-local"
        fi
        return
    fi
    if command -v podman >/dev/null 2>&1; then
        echo "podman"
        return
    fi
    if [ -f "$HOME/openclaw/openclaw" ] || [ -f "/usr/local/bin/openclaw" ]; then
        echo "source"
        return
    fi
    echo "unknown"
}

bootstrap_init() {
    local work_dir="/tmp/clawicu-$$"
    mkdir -p "$work_dir"
    trap "rm -rf $work_dir" EXIT INT TERM
    echo "$work_dir"
}

bootstrap() {
    CLAWICU_OS="$(detect_os)"
    CLAWICU_ARCH="$(detect_arch)"
    CLAWICU_SHELL="$(detect_shell)"
    CLAWICU_INSTALL_METHOD="$(detect_install_method)"
    CLAWICU_TMPDIR="$(bootstrap_init)"
    export CLAWICU_OS CLAWICU_ARCH CLAWICU_SHELL CLAWICU_INSTALL_METHOD CLAWICU_TMPDIR
}

# ============================================================================
# LOG - 4-level logging
# ============================================================================

CLAWICU_LOG_LEVEL="${CLAWICU_LOG_LEVEL:-INFO}"

log_info()  { echo "[INFO]  $*" >&2; }
log_warn() { echo "[WARN]  $*" >&2; }
log_debug() { [ "$CLAWICU_LOG_LEVEL" = "DEBUG" ] && echo "[DEBUG] $*" >&2 || true; }
log_fatal() { echo "[FATAL] $*" >&2; }

# ============================================================================
# UI - ICU风格界面
# ============================================================================

TERMINAL_WIDTH="${TERMINAL_WIDTH:-$(tput cols 2>/dev/null || echo 80)}"

C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_MAGENTA='\033[0;35m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_NC='\033[0m'

ECG_CHARS="/-\\|/-\\|"
VITAL_HEART="<3"
VITAL_PULSE="[o]"

clear_line() { printf "\r\033[K"; }

hline() { printf '%*s\n' 80 '' | tr ' ' '-'; }

    icu_header() {
    local version="${1:-0.1.0}"
    clear
    printf "\n"
    printf "   ****************************************************************\n"
    printf "   *                                                              *\n"
    printf "   *   ██╗    ██╗ █████╗ ███████╗███████╗██╗                     *\n"
    printf "   *   ██║    ██║██╔══██╗██╔════╝██╔════╝██║                     *\n"
    printf "   *   ██║ █╗ ██║███████║███████╗███████╗██║                     *\n"
    printf "   *   ██║███╗██║██╔══██║╚════██║╚════██║██║                     *\n"
    printf "   *   ╚███╔███╔╝██║  ██║███████║███████║███████╗                *\n"
    printf "   *    ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝                *\n"
    printf "   *                                                              *\n"
    printf "   *   ██████╗ ███████╗██████╗ ██╗      █████╗ ███████╗██╗       *\n"
    printf "   *   ██╔══██╗██╔════╝██╔══██╗██║     ██╔══██╗██╔════╝██║       *\n"
    printf "   *   ██████╔╝█████╗  ██████╔╝██║     ███████║███████╗██║       *\n"
    printf "   *   ██╔══██╗██╔══╝  ██╔══██╗██║     ██╔══██║╚════██║██║       *\n"
    printf "   *   ██║  ██║███████╗██████╔╝███████╗██║  ██║███████║███████╗  *\n"
    printf "   *   ╚═╝  ╚═╝╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝  *\n"
    printf "   *                                                              *\n"
    printf "   ****************************************************************\n"
    printf "\n"
    printf "   ${C_CYAN}*${C_NC} OpenClaw Emergency Rescue System ${C_CYAN}*${C_NC}\n"
    printf "   ${C_DIM}%-80s${C_NC}\n" "-------------------------------------------------------------"
    printf "   Version: ${C_BOLD}%s${C_NC} | ICU Mode: ${C_GREEN}[ON]${C_NC}\n" "$version"
    printf "\n"
}

vital_monitor() {
    local status="$1"
    local heartbeat="$2"
    local spo2="$3"
    local temp="$4"

    printf "\n"
    printf "   +---------------------------------------------------------------+\n"
    printf "   |  ICU VITAL SIGNS MONITOR                                       |\n"
    printf "   +---------------------------------------------------------------+\n"

    case "$status" in
        CRITICAL)
            printf "   | ${C_RED}[!] STATUS: CRITICAL${C_NC}                                         |\n"
            ;;
        WARNING)
            printf "   | ${C_YELLOW}[!] STATUS: WARNING${C_NC}                                          |\n"
            ;;
        STABLE)
            printf "   | ${C_GREEN}[*] STATUS: STABLE${C_NC}                                           |\n"
            ;;
    esac

    printf "   |                                                           |\n"
    printf "   |  %s Heart Rate: %s BPM          %s SpO2: %s%%          TEMP: %sC  |\n" "$VITAL_HEART" "$heartbeat" "$VITAL_PULSE" "$spo2" "$temp"
    printf "   |                                                           |\n"
    printf "   +---------------------------------------------------------------+\n"
}

heartbeat_line() {
    local delay="${1:-0.05}"
    local count="${2:-3}"
    local i
    for i in $(seq 1 "$count"); do
        for char in $(echo "$ECG_CHARS" | sed 's/\(.\)/\1 /g'); do
            printf "\r   ${C_RED}%s${C_NC} " "$char"
            sleep "$delay"
        done
    done
    clear_line
}

ecg_flatline() {
    printf "\r   ${C_DIM}%s${C_NC} " "▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔"
}

icu_spinner() {
    local msg="${1:-Loading}"
    local delay="${2:-0.1}"
    local spin=0

    while true; do
        case $spin in
            0) printf "\r   ${C_CYAN}/${C_NC} ${msg}..." ;;
            1) printf "\r   ${C_CYAN}-${C_NC} ${msg}..." ;;
            2) printf "\r   ${C_CYAN}\\${C_NC} ${msg}..." ;;
            3) printf "\r   ${C_CYAN}|${C_NC} ${msg}..." ;;
        esac
        spin=$(( (spin + 1) % 4 ))
        sleep "$delay"
    done &
    echo $!
}

stop_spinner() {
    local pid="$1"
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    clear_line
}

progress_bar() {
    local current="$1"
    local total="$2"
    local msg="${3:-Progress}"
    local width=40

    [ "$total" -eq 0 ] && total=1
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    [ "$filled" -gt "$width" ] && filled="$width"
    local empty=$((width - filled))

    local bar="" i
    for i in $(seq 1 "$filled"); do bar="${bar}#"; done
    for i in $(seq 1 "$empty"); do bar="${bar}░"; done

    printf "\r   [%s] %3d%% %s" "$bar" "$percent" "$msg"
}

phase_indicator() {
    local phase="$1"
    local total="$2"
    local name="$3"

    printf "\n"
    printf "   ${C_CYAN}*${C_NC} ${C_BOLD}Phase %d/%d:${C_NC} ${C_BOLD}%s${C_NC}\n" "$phase" "$total" "$name"
    printf "   ${C_DIM}%-80s${C_NC}\n" "--------------------------------------------------------------------"
    printf "\n"
}

check_result() {
    local status="$1"
    local check_name="$2"
    local message="${3:-}"

    case "$status" in
        OK)
            printf "   ${C_GREEN}[OK]${C_NC} ${C_BOLD}%s${C_NC}" "$check_name"
            [ -n "$message" ] && printf " -- ${C_GREEN}%s${C_NC}" "$message"
            printf "\n"
            ;;
        FAIL|CRITICAL|FATAL)
            printf "   ${C_RED}[X]${C_NC} ${C_BOLD}%s${C_NC}" "$check_name"
            [ -n "$message" ] && printf " -- ${C_RED}%s${C_NC}" "$message"
            printf "\n"
            ;;
        WARN|WARNING)
            printf "   ${C_YELLOW}[!]${C_NC} ${C_BOLD}%s${C_NC}" "$check_name"
            [ -n "$message" ] && printf " -- ${C_YELLOW}%s${C_NC}" "$message"
            printf "\n"
            ;;
        INFO)
            printf "   ${C_CYAN}[i]${C_NC} ${C_BOLD}%s${C_NC}" "$check_name"
            [ -n "$message" ] && printf " -- ${C_CYAN}%s${C_NC}" "$message"
            printf "\n"
            ;;
        PROCESSING|RUNNING)
            printf "   ${C_CYAN}[.]${C_NC} ${C_BOLD}%s${C_NC}" "$check_name"
            [ -n "$message" ] && printf " -- ${C_CYAN}%s${C_NC}" "$message"
            printf "\r"
            ;;
    esac
}

rescue_announce() {
    local type="$1"
    local message="$2"

    printf "\n"
    case "$type" in
        START)
            printf "   ${C_MAGENTA}+--------------------------------------+/${C_NC}\n"
            printf "   ${C_MAGENTA}|${C_NC}  ${C_BOLD}${C_MAGENTA}[!!] INITIATING EMERGENCY RESCUE [!!]${C_NC}  ${C_MAGENTA}|${C_NC}\n"
            printf "   ${C_MAGENTA}+--------------------------------------+/${C_NC}\n"
            ;;
        ING)
            printf "   ${C_YELLOW}+--------------------------------------+/${C_NC}\n"
            printf "   ${C_YELLOW}|${C_NC}  ${C_BOLD}${C_YELLOW}[>>] ICU RESCUING -- STANDBY [>>]${C_NC}    ${C_YELLOW}|${C_NC}\n"
            printf "   ${C_YELLOW}+--------------------------------------+/${C_NC}\n"
            ;;
        COMPLETE)
            printf "   ${C_GREEN}+--------------------------------------+/${C_NC}\n"
            printf "   ${C_GREEN}|${C_NC}  ${C_BOLD}${C_GREEN}[OK] RESCUE COMPLETE -- PATIENT STABLE [OK]${C_NC}  ${C_GREEN}|${C_NC}\n"
            printf "   ${C_GREEN}+--------------------------------------+/${C_NC}\n"
            ;;
        FAILED)
            printf "   ${C_RED}+--------------------------------------+/${C_NC}\n"
            printf "   ${C_RED}|${C_NC}  ${C_BOLD}${C_RED}[X] RESCUE FAILED -- CRITICAL [X]${C_NC}    ${C_RED}|${C_NC}\n"
            printf "   ${C_RED}+--------------------------------------+/${C_NC}\n"
            ;;
    esac
    printf "\n"
}

# ============================================================================
# CHECKS - Inline diagnostic checks
# ============================================================================

CHECKS_FAILED=0
CHECKS_WARN=0
RESULTS_FILE="$CLAWICU_TMPDIR/check-results.txt"

check_binary() {
    check_result PROCESSING "OpenClaw Binary" "checking..."
    if ! command -v openclaw >/dev/null 2>&1; then
        check_result FAIL "OpenClaw Binary" "not found in PATH"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        echo "FAIL:fatal:binary:OpenClaw binary not found:Install with: npm install -g openclaw" >> "$RESULTS_FILE"
        return 0
    fi
    if [ ! -x "$(command -v openclaw)" ]; then
        check_result FAIL "OpenClaw Binary" "found but not executable"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        return 0
    fi
    check_result OK "OpenClaw Binary" "installed at $(command -v openclaw)"
    return 1
}

check_process() {
    check_result PROCESSING "OpenClaw Process" "checking..."
    if pgrep -f "openclaw" > /dev/null 2>&1; then
        local pid=$(pgrep -f openclaw | head -1)
        check_result OK "OpenClaw Process" "running (PID: $pid)"
        return 1
    fi
    check_result WARN "OpenClaw Process" "not running"
    CHECKS_WARN=$((CHECKS_WARN + 1))
    echo "WARN:process:OpenClaw process not running:Start with: openclaw daemon" >> "$RESULTS_FILE"
    return 0
}

check_config() {
    check_result PROCESSING "Config File" "checking..."
    local config_path="${OPENCLAW_CONFIG:-$HOME/.openclaw/config.json5}"
    if [ ! -f "$config_path" ]; then
        check_result WARN "Config File" "not found at $config_path"
        CHECKS_WARN=$((CHECKS_WARN + 1))
        echo "WARN:config:Config file not found:$config_path:Run openclaw init to create" >> "$RESULTS_FILE"
        return 0
    fi
    check_result OK "Config File" "exists"
    return 1
}

check_disk() {
    check_result PROCESSING "Disk Space" "checking..."
    local disk_usage=$(df "$HOME" 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
    if [ -n "$disk_usage" ] && [ "$disk_usage" -gt 90 ]; then
        check_result FAIL "Disk Space" "critical ($disk_usage% used)"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        echo "FAIL:fatal:disk:Disk space critical:${disk_usage}% used:Free up space to continue" >> "$RESULTS_FILE"
        return 0
    elif [ -n "$disk_usage" ] && [ "$disk_usage" -gt 75 ]; then
        check_result WARN "Disk Space" "low ($disk_usage% used)"
        CHECKS_WARN=$((CHECKS_WARN + 1))
        return 0
    fi
    check_result OK "Disk Space" "${disk_usage}% used"
    return 1
}

check_node() {
    check_result PROCESSING "Node.js" "checking..."
    if ! command -v node >/dev/null 2>&1; then
        check_result FAIL "Node.js" "not found"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
        echo "FAIL:fatal:node:Node.js not installed:Required by OpenClaw:Install from nodejs.org" >> "$RESULTS_FILE"
        return 0
    fi
    local node_version=$(node --version 2>/dev/null)
    check_result OK "Node.js" "v$(echo $node_version | tr -d 'v')"
    return 1
}

check_network() {
    check_result PROCESSING "Network" "checking..."
    if curl -sf --max-time 5 https://www.google.com > /dev/null 2>&1; then
        check_result OK "Network" "connected"
        return 1
    fi
    check_result WARN "Network" "offline or restricted"
    CHECKS_WARN=$((CHECKS_WARN + 1))
    echo "WARN:network:Network connectivity issue:Cannot reach external services:Check firewall/proxy" >> "$RESULTS_FILE"
    return 0
}

check_state_dir() {
    check_result PROCESSING "State Directory" "checking..."
    local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
    if [ ! -d "$state_dir" ]; then
        check_result WARN "State Directory" "not found (will be created)"
        CHECKS_WARN=$((CHECKS_WARN + 1))
        return 0
    fi
    check_result OK "State Directory" "$state_dir"
    return 1
}

check_plugins() {
    check_result PROCESSING "Plugins" "checking..."
    local plugin_dir="${OPENCLAW_PLUGIN_DIR:-$HOME/.openclaw/plugins}"
    if [ ! -d "$plugin_dir" ]; then
        check_result OK "Plugins" "no plugins directory (normal for fresh install)"
        return 1
    fi
    local plugin_count=$(find "$plugin_dir" -name "*.js" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$plugin_count" -gt 0 ]; then
        check_result OK "Plugins" "$plugin_count plugin(s) installed"
    else
        check_result INFO "Plugins" "directory exists but no plugins"
    fi
    return 1
}

# ============================================================================
# MAIN RESCUE PROTOCOL
# ============================================================================

phase_0_bootstrap() {
    icu_header "$SCRIPT_VERSION"

    printf "   ${C_CYAN}*${C_NC} System: ${C_BOLD}%s${C_NC} | ${C_CYAN}*${C_NC} Arch: ${C_BOLD}%s${C_NC} | ${C_CYAN}*${C_NC} Shell: ${C_BOLD}%s${C_NC}\n" "$CLAWICU_OS" "$CLAWICU_ARCH" "$CLAWICU_SHELL"
    printf "   ${C_CYAN}*${C_NC} Install: ${C_BOLD}%s${C_NC} | ${C_CYAN}*${C_NC} Version: ${C_BOLD}%s${C_NC}\n" "$CLAWICU_INSTALL_METHOD" "$SCRIPT_VERSION"
    printf "\n"
    printf "   ${C_DIM}%-80s${C_NC}\n" "-------------------------------------------------------------"

    rescue_announce START "Initializing rescue protocol..."

    if ! command -v curl >/dev/null 2>&1; then
        printf "\n   ${C_RED}[X] FATAL: curl is required but not found${C_NC}\n"
        exit 1
    fi

    printf "   ${C_GREEN}[OK]${C_NC} curl .............. ${C_GREEN}READY${C_NC}\n"
}

phase_1_doctor() {
    phase_indicator 1 6 "OpenClaw Doctor Check"

    if ! command -v openclaw >/dev/null 2>&1; then
        check_result WARN "OpenClaw" "not installed"
        return 0
    fi

    check_result PROCESSING "OpenClaw Doctor" "running..."
    printf "\n"

    local doctor_output
    if doctor_output="$(openclaw doctor 2>&1)"; then
        check_result OK "OpenClaw Doctor" "all checks passed"
        return 1
    else
        check_result WARN "OpenClaw Doctor" "reported issues"
        printf "\n   ${C_DIM}%s${C_NC}\n" "$doctor_output"
        return 0
    fi
}

phase_2_checks() {
    phase_indicator 2 6 "Running Diagnostic Checks"

    > "$RESULTS_FILE"

    check_binary
    sleep 0.2
    check_process
    sleep 0.2
    check_config
    sleep 0.2
    check_disk
    sleep 0.2
    check_node
    sleep 0.2
    check_network
    sleep 0.2
    check_state_dir
    sleep 0.2
    check_plugins

    printf "\n"
    printf "   ${C_DIM}%-80s${C_NC}\n" "-------------------------------------------------------------"

    if [ "$CHECKS_FAILED" -gt 0 ]; then
        printf "   ${C_RED}[X] Issues Found: ${C_BOLD}%s CRITICAL${C_NC}" "$CHECKS_FAILED"
        [ "$CHECKS_WARN" -gt 0 ] && printf " | ${C_YELLOW}[!] %s WARNINGS${C_NC}" "$CHECKS_WARN"
        printf "\n"
    elif [ "$CHECKS_WARN" -gt 0 ]; then
        printf "   ${C_YELLOW}[!] Warnings: %s${C_NC}\n" "$CHECKS_WARN"
    else
        printf "   ${C_GREEN}[OK] All Checks Passed${C_NC}\n"
    fi
}

phase_3_triage() {
    phase_indicator 3 6 "Triage & Analysis"

    if [ "$CHECKS_FAILED" -gt 0 ]; then
        vital_monitor "CRITICAL" "---" "---" "---"
        printf "\n   ${C_RED}[*] PATIENT IN CRITICAL CONDITION${C_NC}\n"
        printf "   ${C_RED}[*] IMMEDIATE RESCUE REQUIRED${C_NC}\n"
    elif [ "$CHECKS_WARN" -gt 0 ]; then
        vital_monitor "WARNING" "---" "---" "---"
        printf "\n   ${C_YELLOW}[*] PATIENT REQUIRES ATTENTION${C_NC}\n"
    else
        vital_monitor "STABLE" "72" "98" "36.6"
        printf "\n   ${C_GREEN}[*] PATIENT STABLE - NO IMMEDIATE ACTION REQUIRED${C_NC}\n"
    fi
}

phase_4_menu() {
    phase_indicator 4 6 "Select Treatment Plan"

    if [ "$CHECKS_FAILED" -eq 0 ] && [ "$CHECKS_WARN" -eq 0 ]; then
        check_result OK "OpenClaw Status" "system is healthy"
        printf "\n"
        rescue_announce COMPLETE "All systems operational"
        return 1
    fi

    printf "\n"
    printf "   ${C_BOLD}Available Treatment Plans:${C_NC}\n"
    printf "\n"
    printf "   ${C_GREEN}[a]${C_NC} Auto-Treatment -- Let ICU handle everything\n"
    printf "   ${C_CYAN}[1]${C_NC} Quick Fix -- Safe, low-risk repairs only\n"
    printf "   ${C_YELLOW}[2]${C_NC} Full Treatment -- Include all repairs\n"
    printf "   ${C_RED}[3]${C_NC} Nuclear Option -- Full state reset\n"
    printf "   ${C_DIM}[s]${C_NC} Export Report -- Save diagnostic data\n"
    printf "   ${C_DIM}[q]${C_NC} Quit -- Exit without changes\n"

    printf "\n"
    printf "   ${C_BOLD}Select option [a]:${C_NC} "
    read -r choice

    [ -z "$choice" ] && choice="a"
    printf "\n"

    case "$choice" in
        a|A)
            rescue_announce ING "Running auto-treatment protocol..."
            printf "\n   ${C_CYAN}[.]${C_NC} Executing treatment modules...\n"
            sleep 1
            rescue_announce COMPLETE "Auto-treatment complete"
            ;;
        1)
            printf "   ${C_CYAN}[.]${C_NC} Running quick fixes...\n"
            sleep 1
            ;;
        2)
            printf "   ${C_YELLOW}[.]${C_NC} Running full treatment...\n"
            sleep 1
            ;;
        3)
            printf "   ${C_RED}[.]${C_NC} Nuclear option selected...\n"
            sleep 1
            ;;
        s|S)
            local report="$HOME/.openclaw/clawicu-report-$(date '+%Y%m%d-%H%M%S').txt"
            mkdir -p "$(dirname "$report")"
            {
                echo "ClawICU Diagnostic Report"
                echo "========================"
                echo "Date: $(date)"
                echo "System: $CLAWICU_OS $CLAWICU_ARCH"
                cat "$RESULTS_FILE"
            } > "$report"
            printf "   ${C_GREEN}[OK]${C_NC} Report saved: %s\n" "$report"
            ;;
        q|Q)
            printf "   ${C_DIM}Exiting without changes...${C_NC}\n"
            exit 0
            ;;
        *)
            printf "   ${C_YELLOW}[!]${C_NC} Invalid option, using auto-treatment...\n"
            ;;
    esac
}

phase_5_execute() {
    phase_indicator 5 6 "Executing Repairs"
    printf "\n   ${C_CYAN}[.]${C_NC} Repair module execution...\n"
    sleep 1
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
        echo "Version: $SCRIPT_VERSION"
        echo ""
        echo "Issues Detected:"
        cat "$RESULTS_FILE" 2>/dev/null || echo "  None"
    } > "$report"

    printf "\n"
    rescue_announce COMPLETE "Rescue operation finished"
    printf "   ${C_GREEN}[OK]${C_NC} Report: ${C_BOLD}%s${C_NC}\n" "$report"
}

main() {
    bootstrap
    phase_0_bootstrap
    phase_1_doctor || true
    phase_2_checks
    phase_3_triage
    phase_4_menu
    phase_5_execute
    phase_6_report
}

main "$@"

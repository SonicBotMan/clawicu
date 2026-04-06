#!/bin/sh
# ClawICU - OpenClaw Emergency Rescue System
# Bundled rescue script - auto-generated
# DO NOT EDIT - edit source files and rebuild

set -e

CLAWICU_VERSION="0.2.0"
CLAWICU_TMPDIR="${CLAWICU_TMPDIR:-/tmp/clawicu-$$}"

# === LIBRARIES ===

# --- lib/bootstrap.sh ---
# bootstrap.sh - OS/shell detection, install method detection, temp dir setup
# NOTE: Do NOT put 'set -e' here - the bundle inlines all modules into one
# script and set -e from individual modules causes premature exits.

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# Detect architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64)        echo "x86_64" ;;
        arm64|aarch64) echo "arm64" ;;
        *)             echo "unknown" ;;
    esac
}

# Detect shell capabilities
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

# Detect install method (npm/Docker/Podman/source)
detect_install_method() {
    # Check if running in Docker
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        echo "docker"
        return
    fi

    # Check if openclaw is installed via npm
    if command -v openclaw >/dev/null 2>&1; then
        if [ -d "$HOME/.npm" ] || [ -d "/usr/local/lib/node_modules/openclaw" ]; then
            echo "npm-global"
            return
        fi
        echo "npm-local"
        return
    fi

    # Check if podman is available
    if command -v podman >/dev/null 2>&1; then
        echo "podman"
        return
    fi

    # Check for source install
    if [ -f "$HOME/openclaw/openclaw" ] || [ -f "/usr/local/bin/openclaw" ]; then
        echo "source"
        return
    fi

    echo "unknown"
}

# Main bootstrap - creates the temp working directory in the CURRENT shell
# so the trap and mkdir both take effect in the parent process (not a subshell).
bootstrap() {
    CLAWICU_OS="$(detect_os)"
    CLAWICU_ARCH="$(detect_arch)"
    CLAWICU_SHELL="$(detect_shell)"
    CLAWICU_INSTALL_METHOD="$(detect_install_method)"

    # Determine and create the temp dir directly here (NOT via $(...) subshell).
    # Using $(...) would run the mkdir inside a subshell whose EXIT trap would
    # immediately delete the directory before the parent shell can use it.
    CLAWICU_TMPDIR="${CLAWICU_TMPDIR:-/tmp/clawicu-$$}"
    mkdir -p "$CLAWICU_TMPDIR"

    # Register cleanup trap in the current (parent) shell
    # shellcheck disable=SC2064
    trap "rm -rf '$CLAWICU_TMPDIR'" EXIT INT TERM

    export CLAWICU_OS CLAWICU_ARCH CLAWICU_SHELL CLAWICU_INSTALL_METHOD CLAWICU_TMPDIR
}

# --- lib/log.sh ---
# log.sh - 4-level logging (FATAL/WARN/INFO/DEBUG), colors, file output


CLAWICU_LOG_LEVEL="${CLAWICU_LOG_LEVEL:-INFO}"
CLAWICU_LOG_FILE="${CLAWICU_LOG_FILE:-}"

# Colors
LOG_FATAL='\033[0;31m'   # Red
LOG_WARN='\033[0;33m'    # Yellow
LOG_INFO='\033[0;32m'    # Green
LOG_DEBUG='\033[0;36m'   # Cyan
LOG_NC='\033[0m'         # No Color

# Timestamps
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Log to file only (no stdout)
log_file() {
    if [ -n "$CLAWICU_LOG_FILE" ]; then
        echo "[$(timestamp)] $*" >> "$CLAWICU_LOG_FILE"
    fi
}

# Log with level and color
log() {
    local level="$1"
    shift
    local msg="$*"
    local color=""
    local enabled=0

    case "$level" in
        FATAL) color="$LOG_FATAL"; enabled=1 ;;
        WARN)  color="$LOG_WARN"; enabled=1 ;;
        INFO)  color="$LOG_INFO"; enabled=1 ;;
        DEBUG) color="$LOG_DEBUG";
            if [ "$CLAWICU_LOG_LEVEL" = "DEBUG" ]; then enabled=1; fi
            ;;
    esac

    if [ "$enabled" = 1 ]; then
        echo "${color}[$(timestamp)] [$level] $msg${LOG_NC}"
        log_file "[$level] $msg"
    fi
}

log_fatal() { log "FATAL" "$@"; }
log_warn()  { log "WARN" "$@"; }
log_info()  { log "INFO" "$@"; }
log_debug() { log "DEBUG" "$@"; }

# --- lib/ui.sh ---
# ui.sh - Terminal UI with automatic ASCII/Unicode detection

# Terminal width
TERMINAL_WIDTH="${TERMINAL_WIDTH:-$(tput cols 2>/dev/null || echo 80)}"

# Colors
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_MAGENTA='\033[0;35m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_NC='\033[0m'
C_BG_RED='\033[41m'
C_BG_GREEN='\033[42m'

# ---------------------------------------------------------------------------
# Auto-detect Unicode support.
# Safe if LANG/LC_ALL/LC_CTYPE contains UTF-8, and locale charmap returns UTF-8.
# ---------------------------------------------------------------------------
_detect_unicode() {
    local lang="${LANG:-}${LC_ALL:-}${LC_CTYPE:-}"
    case "$lang" in
        *[Uu][Tt][Ff][-_]8*|*[Uu][Tt][Ff]8*) return 0 ;;
    esac
    if command -v locale >/dev/null 2>&1; then
        case "$(locale charmap 2>/dev/null)" in
            UTF-8|utf-8) return 0 ;;
        esac
    fi
    return 1
}

if _detect_unicode; then
    UI_UNICODE=1
else
    UI_UNICODE=0
fi

# Character sets - chosen once at startup
if [ "$UI_UNICODE" = "1" ]; then
    CH_DIAMOND="*"
    CH_BULLET="*"
    CH_CHECK="[OK]"
    CH_CROSS="[!!]"
    CH_WARN="[!]"
    CH_INFO="[i]"
    CH_SPIN="/-\|"
    CH_HLINE_CHAR="-"
    CH_BAR_FULL="#"
    CH_BAR_EMPTY="-"
    CH_BOX_TL="+"
    CH_BOX_TR="+"
    CH_BOX_BL="+"
    CH_BOX_BR="+"
    CH_BOX_H="-"
    CH_BOX_V="|"
    CH_BOX_LT="+"
    CH_BOX_RT="+"
    # Use Unicode for richer display
    CH_DIAMOND="*"
    CH_CHECK="[OK]"
    CH_CROSS="[!!]"
    CH_WARN="[!]"
    CH_INFO="[i]"
    CH_SPIN="/-\\|"
    CH_HLINE_CHAR="-"
    CH_BAR_FULL="="
    CH_BAR_EMPTY="-"
    CH_DOT="*"
else
    CH_DIAMOND="*"
    CH_CHECK="[OK]"
    CH_CROSS="[!!]"
    CH_WARN="[!]"
    CH_INFO="[i]"
    CH_SPIN="/-\\|"
    CH_HLINE_CHAR="-"
    CH_BAR_FULL="="
    CH_BAR_EMPTY="-"
    CH_DOT="*"
fi

# Clear line
clear_line() {
    printf "\r\033[K"
}

# Print a horizontal rule of dashes
hline() {
    printf '   '
    printf '%*s' "$((TERMINAL_WIDTH - 3))" '' | tr ' ' "$CH_HLINE_CHAR"
    printf '\n'
}

# Simple title box using ASCII
box() {
    local title="$1"
    local width="${2:-60}"
    printf "   +%s+\n" "$(printf '%*s' "$width" '' | tr ' ' '-')"
    printf "   |  %-${width}s|\n" "$title"
    printf "   +%s+\n" "$(printf '%*s' "$width" '' | tr ' ' '-')"
}

# Header - pure ASCII art (safe everywhere)
icu_header() {
    local version="${1:-0.1.0}"
    clear
    printf "\n"
    printf "   ============================================================\n"
    printf "    ____  __    ___  _    _____  ____  __  __\n"
    printf "   / ___||  |  / _ \\| |  |_   _|/ ___||  \\/  |\n"
    printf "  | |    | | | |_| | |    | | | |    | |\\/| |\n"
    printf "  | |___ | |_|  _  | |___ | | | |___ | |  | |\n"
    printf "   \\____||____|_| |_|_____|___|  \\____||_|  |_|\n"
    printf "   OpenClaw Emergency Rescue System\n"
    printf "   ============================================================\n"
    printf "   Version: %s\n" "$version"
    printf "\n"
}

# Compact vital signs display (ASCII-safe)
vital_monitor() {
    local status="$1"
    printf "\n"
    printf "   +-----------------------------------------------+\n"
    printf "   |  ICU VITAL SIGNS MONITOR                      |\n"
    printf "   +-----------------------------------------------+\n"
    case "$status" in
        CRITICAL) printf "   |  STATUS: CRITICAL                             |\n" ;;
        WARNING)  printf "   |  STATUS: WARNING                              |\n" ;;
        STABLE)   printf "   |  STATUS: STABLE                               |\n" ;;
    esac
    printf "   +-----------------------------------------------+\n"
}

# Spinner - returns PID, must be stopped with stop_spinner
icu_spinner() {
    local msg="${1:-Loading}"
    local delay="${2:-0.1}"
    local spin=0
    while true; do
        case $spin in
            0) printf "\r   | %s..." "$msg" ;;
            1) printf "\r   / %s..." "$msg" ;;
            2) printf "\r   - %s..." "$msg" ;;
            3) printf "\r   \\ %s..." "$msg" ;;
        esac
        spin=$(( (spin + 1) % 4 ))
        sleep "$delay"
    done &
    echo $!
}

stop_spinner() {
    local pid="$1"
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    clear_line
}

# Progress bar using = and - (ASCII-safe)
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

    local bar=""
    local i
    for i in $(seq 1 "$filled"); do bar="${bar}="; done
    for i in $(seq 1 "$empty");  do bar="${bar}-"; done

    printf "\r   [%s] %3d%% %s" "$bar" "$percent" "$msg"
}

# Phase indicator - the line that was showing garbled characters
phase_indicator() {
    local phase="$1"
    local total="$2"
    local name="$3"

    printf "\n"
    printf "   ${C_CYAN}%s${C_NC} ${C_BOLD}Phase %d/%d:${C_NC} ${C_BOLD}%s${C_NC}\n" \
        "$CH_DIAMOND" "$phase" "$total" "$name"
    printf "   ${C_DIM}"
    printf '%*s' "$((TERMINAL_WIDTH - 3))" '' | tr ' ' '-'
    printf "${C_NC}\n"
}

# Check result line
check_result() {
    local status="$1"
    local check_name="$2"
    local message="${3:-}"

    case "$status" in
        OK)
            printf "   ${C_GREEN}%s${C_NC} ${C_BOLD}%s${C_NC}" "$CH_CHECK" "$check_name"
            [ -n "$message" ] && printf " - ${C_GREEN}%s${C_NC}" "$message"
            printf "\n"
            ;;
        FAIL|CRITICAL|FATAL)
            printf "   ${C_RED}%s${C_NC} ${C_BOLD}%s${C_NC}" "$CH_CROSS" "$check_name"
            [ -n "$message" ] && printf " - ${C_RED}%s${C_NC}" "$message"
            printf "\n"
            ;;
        WARN|WARNING)
            printf "   ${C_YELLOW}%s${C_NC} ${C_BOLD}%s${C_NC}" "$CH_WARN" "$check_name"
            [ -n "$message" ] && printf " - ${C_YELLOW}%s${C_NC}" "$message"
            printf "\n"
            ;;
        INFO)
            printf "   ${C_CYAN}%s${C_NC} ${C_BOLD}%s${C_NC}" "$CH_INFO" "$check_name"
            [ -n "$message" ] && printf " - ${C_CYAN}%s${C_NC}" "$message"
            printf "\n"
            ;;
        PROCESSING|RUNNING)
            printf "   ${C_CYAN}...${C_NC} ${C_BOLD}%s${C_NC}" "$check_name"
            [ -n "$message" ] && printf " - ${C_CYAN}%s${C_NC}" "$message"
            printf "\r"
            ;;
    esac
}

# Rescue announcement box (ASCII-safe)
rescue_announce() {
    local type="$1"
    local message="$2"

    printf "\n"
    case "$type" in
        START)
            printf "   ${C_MAGENTA}+---------------------------------------+${C_NC}\n"
            printf "   ${C_MAGENTA}|${C_NC}  ${C_BOLD}${C_MAGENTA}[!!] INITIATING EMERGENCY RESCUE${C_NC}    ${C_MAGENTA}|${C_NC}\n"
            printf "   ${C_MAGENTA}+---------------------------------------+${C_NC}\n"
            ;;
        ING)
            printf "   ${C_YELLOW}+---------------------------------------+${C_NC}\n"
            printf "   ${C_YELLOW}|${C_NC}  ${C_BOLD}${C_YELLOW}[>>] ICU RESCUING -- STANDBY${C_NC}        ${C_YELLOW}|${C_NC}\n"
            printf "   ${C_YELLOW}+---------------------------------------+${C_NC}\n"
            ;;
        COMPLETE)
            printf "   ${C_GREEN}+---------------------------------------+${C_NC}\n"
            printf "   ${C_GREEN}|${C_NC}  ${C_BOLD}${C_GREEN}[OK] RESCUE COMPLETE - STABLE${C_NC}       ${C_GREEN}|${C_NC}\n"
            printf "   ${C_GREEN}+---------------------------------------+${C_NC}\n"
            ;;
        FAILED)
            printf "   ${C_RED}+---------------------------------------+${C_NC}\n"
            printf "   ${C_RED}|${C_NC}  ${C_BOLD}${C_RED}[!!] RESCUE FAILED - CRITICAL${C_NC}       ${C_RED}|${C_NC}\n"
            printf "   ${C_RED}+---------------------------------------+${C_NC}\n"
            ;;
    esac
    printf "\n"
}

# Heartbeat line - simple ASCII animation
heartbeat_line() {
    local delay="${1:-0.05}"
    local count="${2:-2}"
    local i
    for i in $(seq 1 "$count"); do
        printf "\r   |  .  .  "
        sleep "$delay"
        printf "\r   | /\\ /\\ "
        sleep "$delay"
        printf "\r   |/  V  \\"
        sleep "$delay"
    done
    clear_line
}

# ECG flatline
ecg_flatline() {
    printf "\r   ${C_DIM}------------------------------------------------${C_NC} "
}

# Menu box
icu_menu() {
    local title="$1"
    local width="${2:-50}"
    printf "\n"
    printf "   +%s+\n" "$(printf '%*s' "$width" '' | tr ' ' '-')"
    printf "   |  %s\n" "$title"
    printf "   +%s+\n" "$(printf '%*s' "$width" '' | tr ' ' '-')"
}

# Scan line (simplified)
scan_line() {
    local i
    for i in $(seq 1 20); do
        printf "\r   [%s%s]" "$(printf '%*s' "$i" '' | tr ' ' '=')" "$(printf '%*s' "$((20-i))" '' | tr ' ' '-')"
        sleep 0.03
    done
    clear_line
}

# Pulse OK (simple)
pulse_ok() {
    local delay="${1:-0.5}"
    printf "   <3 "
    sleep "$delay"
    printf "\b\b\b   "
    sleep "$delay"
}

# Visual beep
visual_beep() {
    printf "\a"
    sleep 0.1
    printf "\a"
}

# --- lib/backup.sh ---
# backup.sh - tar.gz backup engine with create/restore/list/verify

# Backup directory
CLAWICU_BACKUP_DIR="${CLAWICU_BACKUP_DIR:-$HOME/.openclaw/backups}"

# Create a timestamped backup
backup_create() {
    local label="${1:-manual}"
    local backup_dir="$CLAWICU_BACKUP_DIR"
    local timestamp="$(date '+%Y%m%d-%H%M%S')"
    local backup_name="clawicu-$label-$timestamp.tar.gz"
    local backup_path="$backup_dir/$backup_name"

    mkdir -p "$backup_dir"

    # Backup state directory
    local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

    tar -czf "$backup_path" -C "$state_dir" . 2>/dev/null || true

    # Create manifest
    echo "$timestamp" > "$backup_path.meta"
    echo "$label" >> "$backup_path.meta"

    echo "$backup_path"
}

# Restore from backup
backup_restore() {
    local backup_path="$1"
    local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

    if [ ! -f "$backup_path" ]; then
        echo "Backup not found: $backup_path" >&2
        return 1
    fi

    # Create a safety backup first
    local safety_backup="$state_dir.pre-restore-$(date '+%Y%m%d-%H%M%S').tar.gz"
    tar -czf "$safety_backup" -C "$state_dir" . 2>/dev/null || true

    # Restore
    tar -xzf "$backup_path" -C "$state_dir"
}

# List backups
backup_list() {
    local backup_dir="$CLAWICU_BACKUP_DIR"

    if [ ! -d "$backup_dir" ]; then
        echo "No backups found"
        return
    fi

    ls -lht "$backup_dir"/*.tar.gz 2>/dev/null | awk '{print $6, $7, $8, $9}' || echo "No backups found"
}

# Verify backup integrity
backup_verify() {
    local backup_path="$1"

    if [ ! -f "$backup_path" ]; then
        return 1
    fi

    tar -tzf "$backup_path" >/dev/null 2>&1
}

# Leverage openclaw backup if available
backup_try_openclaw() {
    if command -v openclaw >/dev/null 2>&1; then
        openclaw backup "$@" 2>/dev/null
        return $?
    fi
    return 1
}

# --- lib/state.sh ---
# state.sh - Rollback state machine

CLAWICU_STATE_FILE="${CLAWICU_STATE_FILE:-$CLAWICU_TMPDIR/state.json}"

# State machine: push state before each repair
state_push() {
    local action="$1"
    local timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    # Simple JSON state tracking
    echo "{\"action\": \"$action\", \"timestamp\": \"$timestamp\"}" >> "$CLAWICU_STATE_FILE"
}

# Get last state
state_last() {
    if [ -f "$CLAWICU_STATE_FILE" ]; then
        tail -1 "$CLAWICU_STATE_FILE"
    fi
}

# Clear state
state_clear() {
    if [ -f "$CLAWICU_STATE_FILE" ]; then
        rm "$CLAWICU_STATE_FILE"
    fi
}

# Rollback: restore from most recent backup
state_rollback() {
    local last_action="$(state_last)"

    if [ -z "$last_action" ]; then
        echo "No state to rollback" >&2
        return 1
    fi

    # Find most recent backup
    local backup_dir="${CLAWICU_BACKUP_DIR:-$HOME/.openclaw/backups}"
    local latest="$(ls -t "$backup_dir"/*.tar.gz 2>/dev/null | head -1)"

    if [ -z "$latest" ]; then
        echo "No backup found to rollback to" >&2
        return 1
    fi

    echo "Rolling back: $last_action"
    backup_restore "$latest"
}

# --- lib/verify.sh ---
# verify.sh - SHA256 generation and verification

# Generate SHA256 for a file
sha256_generate() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return 1
    fi

    case "$(uname -s)" in
        Darwin*)
            shasum -a 256 "$file" | awk '{print $1}'
            ;;
        Linux*)
            sha256sum "$file" | awk '{print $1}'
            ;;
        *)
            # Fallback using OpenSSL
            openssl dgst -sha256 "$file" | sed 's/^.* //'
            ;;
    esac
}

# Verify file against expected hash
sha256_verify() {
    local file="$1"
    local expected_hash="$2"

    local actual_hash="$(sha256_generate "$file")"

    if [ "$actual_hash" = "$expected_hash" ]; then
        return 0
    else
        echo "SHA256 mismatch!" >&2
        echo "Expected: $expected_hash" >&2
        echo "Actual:   $actual_hash" >&2
        return 1
    fi
}

# Generate checksums file for a directory
sha256_generate_checksums() {
    local dir="$1"
    local output="${2:-SHA256SUMS}"

    (cd "$dir" && find . -type f | while read -r f; do
        echo "$(sha256_generate "$f")  $f"
    done) > "$output"
}

# Verify all files in checksums file
sha256_verify_checksums() {
    local checksums_file="$1"
    local dir="$(dirname "$checksums_file")"

    (cd "$dir" && sha256sum -c "$checksums_file")
}

# === CHECK MODULES ===

# --- check-binary.sh ---
# check-binary.sh - Detect if openclaw binary is missing or not executable

check_binary() {
    SEVERITY="fatal"
    
    if ! command -v openclaw >/dev/null 2>&1; then
        MESSAGE="OpenClaw binary not found in PATH"
        return 0
    fi
    
    if [ ! -x "$(command -v openclaw)" ]; then
        MESSAGE="OpenClaw binary found but is not executable"
        return 0
    fi
    
    # Binary found and executable
    return 1
}

# --- check-channel-policy.sh ---
# check-channel-policy.sh - Detect channel configuration issues
# Based on real-world repair of 小文 (192.168.11.219)
#
# 问题: groupPolicy='allowlist' + requireMention=true 导致私信不响应
# 解决方案: 将 groupPolicy 改为 'open' 或移除 requireMention

check_channel_policy() {
    SEVERITY="warn"
    
    local config_file="$HOME/.openclaw/openclaw.json"
    [ -f "$config_file" ] || return 1
    
    # 需要 jq 解析 JSON
    command -v jq >/dev/null 2>&1 || return 1
    
    # 1. 检查 Discord 是否启用
    local discord_enabled
    discord_enabled=$(jq -r '.channels.discord.enabled // false' "$config_file" 2>/dev/null)
    [ "$discord_enabled" = "true" ] || return 1
    
    # 2. 检查 Discord groupPolicy
    local discord_policy
    discord_policy=$(jq -r '.channels.discord.groupPolicy // empty' "$config_file" 2>/dev/null)
    
    if [ "$discord_policy" = "allowlist" ]; then
        # 3. 检查是否有 requireMention
        local has_require_mention
        has_require_mention=$(jq '[.channels.discord.guilds[]?.requireMention // false] | any' "$config_file" 2>/dev/null)
        
        if [ "$has_require_mention" = "true" ]; then
            MESSAGE="Discord DMs may not work: groupPolicy='allowlist' with requireMention=true"
            DETAILS="Direct messages to Discord bot will be ignored. Fix: Change groupPolicy to 'open' or set requireMention to false."
            return 0
        fi
    fi
    
    # 4. 检查 allowFrom 是否为空
    local allow_from_count
    allow_from_count=$(jq '.channels.discord.allowFrom // [] | length' "$config_file" 2>/dev/null)
    
    if [ "$allow_from_count" = "0" ] && [ "$discord_policy" != "open" ]; then
        MESSAGE="Discord allowFrom is empty - no users can message the bot"
        DETAILS="Add user IDs to allowFrom array to allow specific users to message the bot, or set groupPolicy to 'open'."
        return 0
    fi
    
    return 1  # No channel policy issues
}

# --- check-config-schema.sh ---
# check-config-schema.sh - Detect invalid config field values (port, auth, etc.)

check_config_schema() {
    SEVERITY="warn"
    
    local config_path="${OPENCLAW_CONFIG:-$HOME/.openclaw/config.json5}"
    
    if [ ! -f "$config_path" ]; then
        return 1
    fi
    
    if command -v node >/dev/null 2>&1; then
        local validation=$(node -e "
            const config = require('json5').parse(require('fs').readFileSync('$config_path', 'utf8'));
            const issues = [];
            
            if (config.port && (config.port < 1 || config.port > 65535)) {
                issues.push('Port must be 1-65535');
            }
            
            if (config.auth && typeof config.auth !== 'object') {
                issues.push('auth must be an object');
            }
            
            if (issues.length > 0) {
                console.log(issues.join(', '));
                process.exit(1);
            }
        " 2>&1)
        
        if [ $? -ne 0 ]; then
            MESSAGE="Config has invalid field values: $validation"
            return 0
        fi
    fi
    
    return 1
}

# --- check-config.sh ---
# check-config.sh - Detect invalid JSON5 config file
#
# OpenClaw config: ~/.openclaw/openclaw.json (JSON5 format, unquoted keys allowed)
# Reference: https://docs.openclaw.ai/gateway/configuration

check_config() {
    SEVERITY="fatal"

    # OpenClaw config is always ~/.openclaw/openclaw.json
    local config_path="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"

    # Accept legacy .json5 extension as fallback
    if [ ! -f "$config_path" ]; then
        local alt="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}/openclaw.json5"
        [ -f "$alt" ] && config_path="$alt"
    fi

    if [ ! -f "$config_path" ]; then
        # Missing config is not fatal - OpenClaw uses safe defaults when absent
        SEVERITY="warn"
        MESSAGE="Config file not found: $config_path"
        DETAILS="OpenClaw will use built-in defaults. Run 'openclaw onboard' to create one."
        return 0
    fi

    # Empty file is always broken
    local size
    size=$(wc -c < "$config_path" 2>/dev/null || echo 0)
    if [ "$size" -eq 0 ]; then
        MESSAGE="Config file is empty: $config_path"
        DETAILS="Run 'openclaw doctor --fix' or restore from backup"
        return 0
    fi

    # Preferred: let OpenClaw validate its own config (catches schema errors too)
    if command -v openclaw >/dev/null 2>&1; then
        if openclaw config validate 2>/dev/null; then
            return 1   # no issue
        else
            MESSAGE="Config file failed OpenClaw schema validation"
            DETAILS="Run 'openclaw doctor' for details, or 'openclaw doctor --fix' to auto-repair"
            return 0
        fi
    fi

    # Fallback: structural brace balance check
    local open_count close_count
    open_count=$(grep -o '{' "$config_path" | wc -l)
    close_count=$(grep -o '}' "$config_path" | wc -l)

    if [ "$open_count" -ne "$close_count" ]; then
        MESSAGE="Config file has unbalanced braces (${open_count} '{' vs ${close_count} '}')"
        DETAILS="Edit $config_path to fix the syntax"
        return 0
    fi

    if ! grep -q '}' "$config_path"; then
        MESSAGE="Config file appears incomplete (no closing brace)"
        DETAILS="Edit $config_path to fix the syntax"
        return 0
    fi

    # Fallback: try Python3 JSON5-lenient parse
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "
import re, json, sys
txt = open(sys.argv[1]).read()
txt = re.sub(r'//.*', '', txt)
txt = re.sub(r'/\*.*?\*/', '', txt, flags=re.DOTALL)
txt = re.sub(r',\s*([}\]])', r'\1', txt)
json.loads(txt)
" "$config_path" 2>/dev/null; then
            MESSAGE="Config file has invalid JSON5 syntax"
            DETAILS="Run 'openclaw doctor' for details or restore from backup"
            return 0
        fi
    elif command -v node >/dev/null 2>&1; then
        # Node: attempt JSON.parse after stripping comments/trailing commas
        if ! node -e "
const fs = require('fs');
let txt = fs.readFileSync(process.argv[1], 'utf8');
txt = txt.replace(/\/\/.*/g, '').replace(/\/\*[\s\S]*?\*\//g, '').replace(/,\s*([}\]])/g, '\$1');
JSON.parse(txt);
" "$config_path" 2>/dev/null; then
            MESSAGE="Config file has invalid JSON5 syntax"
            DETAILS="Run 'openclaw doctor' for details or restore from backup"
            return 0
        fi
    fi

    return 1   # no issue detected
}

# --- check-credentials.sh ---
# check-credentials.sh - Detect missing provider API keys

check_credentials() {
    SEVERITY="warn"
    
    local creds_dir="${OPENCLAW_CRED_DIR:-$HOME/.openclaw/credentials}"
    
    if [ ! -d "$creds_dir" ]; then
        MESSAGE="Credentials directory not found: $creds_dir"
        return 0
    fi
    
    local missing=""
    
    for provider in openai anthropic; do
        local provider_file="$creds_dir/$provider.env"
        if [ ! -f "$provider_file" ] && [ ! -f "$creds_dir/$provider" ]; then
            missing="$missing $provider"
        fi
    done
    
    if [ -n "$missing" ]; then
        MESSAGE="Provider credentials missing:$missing"
        DETAILS="Add API keys to $creds_dir/<provider>.env"
        return 0
    fi
    
    return 1
}

# --- check-daemon.sh ---
# check-daemon.sh - Detect if launchd/systemd service not installed

check_daemon() {
    SEVERITY="warn"
    
    case "$(uname -s)" in
        Darwin*)
            # Check for launchd plist
            local plist="$HOME/Library/LaunchAgents/ai.openclaw.plist"
            if [ ! -f "$plist" ]; then
                MESSAGE="launchd plist not found for OpenClaw daemon"
                DETAILS="Expected at: $plist"
                return 0
            fi
            ;;
        Linux*)
            # OpenClaw installs a user-level service named 'openclaw-gateway'
            local unit_dir="$HOME/.config/systemd/user"
            local unit=""
            # Check both possible unit file names
            if [ -f "$unit_dir/openclaw-gateway.service" ]; then
                unit="$unit_dir/openclaw-gateway.service"
            elif [ -f "$unit_dir/openclaw.service" ]; then
                unit="$unit_dir/openclaw.service"
            fi
            # Also check via systemctl (unit may be installed system-wide)
            if [ -z "$unit" ] && command -v systemctl >/dev/null 2>&1; then
                if systemctl --user list-unit-files "openclaw*.service" 2>/dev/null | grep -q "openclaw"; then
                    return 1  # Unit found via systemctl
                fi
            fi
            if [ -z "$unit" ]; then
                MESSAGE="systemd unit not found for OpenClaw daemon"
                DETAILS="Run: openclaw daemon install"
                return 0
            fi
            ;;
    esac
    
    return 1
}

# --- check-disk.sh ---
# check-disk.sh - Detect low disk space

check_disk() {
    SEVERITY="warn"
    
    local min_free_mb="${CLAWICU_MIN_FREE_MB:-100}"
    
    case "$(uname -s)" in
        Darwin*)
            local free_space="$(df -k "$HOME" 2>/dev/null | tail -1 | awk '{print $4}')"
            local free_mb=$((free_space / 1024))
            ;;
        Linux*)
            local free_space="$(df -k "$HOME" 2>/dev/null | tail -1 | awk '{print $4}')"
            local free_mb=$((free_space / 1024))
            ;;
    esac
    
    if [ -n "$free_mb" ] && [ "$free_mb" -lt "$min_free_mb" ]; then
        MESSAGE="Low disk space: ${free_mb}MB free (minimum ${min_free_mb}MB recommended)"
        return 0
    fi
    
    return 1
}

# --- check-docker.sh ---
# check-docker.sh - Detect Docker/Podman container issues

check_docker() {
    SEVERITY="warn"
    
    # Only relevant if inside a container
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        # Check if Docker daemon is accessible
        if ! docker info >/dev/null 2>&1; then
            MESSAGE="Docker container running but Docker daemon not accessible"
            return 0
        fi
        
        # Check if openclaw container is actually running
        if ! docker ps --format '{{.Names}}' | grep -q openclaw; then
            MESSAGE="OpenClaw container not found running"
            return 0
        fi
        
        MESSAGE="Docker container environment detected"
        return 1
    fi
    
    # Not in Docker - skip this check
    return 1
}

# --- check-envvars.sh ---
# check-envvars.sh - Detect conflicting OPENCLAW_* environment variables

check_envvars() {
    SEVERITY="info"
    
    local conflicts=""
    
    if [ -n "$OPENCLAW_STATE_DIR" ] && [ -n "$CLAWICU_STATE_DIR" ]; then
        conflicts="$conflicts OPENCLAW_STATE_DIR vs CLAWICU_STATE_DIR"
    fi
    
    if [ -n "$OPENCLAW_CONFIG" ] && [ -n "$CLAWICU_CONFIG" ]; then
        conflicts="$conflicts OPENCLAW_CONFIG vs CLAWICU_CONFIG"
    fi
    
    if [ -n "$conflicts" ]; then
        MESSAGE="Conflicting environment variables detected:$conflicts"
        return 0
    fi
    
    return 1
}

# --- check-exec-approvals.sh ---
# check-exec-approvals.sh - Detect unparseable exec-approvals.json

check_exec_approvals() {
    SEVERITY="info"
    
    local approvals_file="${OPENCLAW_STATE_DIR:-$HOME/.openclaw/exec-approvals.json}"
    
    if [ ! -f "$approvals_file" ]; then
        return 1
    fi
    
    if ! node -e "JSON.parse(require('fs').readFileSync('$approvals_file', 'utf8'))" 2>/dev/null; then
        MESSAGE="exec-approvals.json is not valid JSON"
        return 0
    fi
    
    return 1
}

# --- check-gateway.sh ---
# check-gateway.sh - Detect if gateway is running on port 18789

check_gateway() {
    SEVERITY="fatal"
    
    local port="${OPENCLAW_GATEWAY_PORT:-18789}"
    
    case "$(uname -s)" in
        Darwin*)
            if nc -z -w 2 localhost "$port" 2>/dev/null; then
                return 1
            fi
            ;;
        Linux*)
            if command -v ss >/dev/null 2>&1; then
                if ss -tuln 2>/dev/null | grep -q ":$port "; then
                    return 1
                fi
            elif nc -z -w 2 localhost "$port" 2>/dev/null; then
                return 1
            fi
            ;;
    esac
    
    if command -v curl >/dev/null 2>&1; then
        if curl -sf "http://localhost:$port/healthz" >/dev/null 2>&1; then
            return 1
        fi
    fi
    
    MESSAGE="Gateway not running on port $port"
    DETAILS="OpenClaw gateway should be listening on port $port"
    return 0
}

# --- check-install-method.sh ---
# check-install-method.sh - Detect installation type (npm/Docker/Podman/source)

check_install_method() {
    SEVERITY="warn"
    
    local method="unknown"
    
    # Check Docker
    if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        method="docker"
    elif command -v openclaw >/dev/null 2>&1; then
        # Check if npm global
        local openclaw_path="$(command -v openclaw)"
        if echo "$openclaw_path" | grep -q "node_modules"; then
            method="npm-global"
        else
            method="npm-local"
        fi
    elif command -v podman >/dev/null 2>&1; then
        method="podman"
    elif [ -f "$HOME/openclaw/openclaw" ] || [ -f "/usr/local/bin/openclaw" ]; then
        method="source"
    fi
    
    MESSAGE="OpenClaw installed via: $method"
    CLAWICU_INSTALL_METHOD="$method"
    return 1  # This is informational, not an error
}

# --- check-node.sh ---
# check-node.sh - Detect if Node.js is missing or version < 22.12

check_node() {
    SEVERITY="fatal"
    
    if ! command -v node >/dev/null 2>&1; then
        MESSAGE="Node.js not found - OpenClaw requires Node.js"
        return 0
    fi
    
    # Get version (node --version returns v22.14.0 format)
    local node_version="$(node --version 2>/dev/null | sed 's/v//')"
    local major="$(echo "$node_version" | cut -d. -f1)"
    local minor="$(echo "$node_version" | cut -d. -f2)"
    local patch="$(echo "$node_version" | cut -d. -f3)"
    
    # Check if version < 22.12
    if [ "$major" -lt 22 ]; then
        MESSAGE="Node.js version $node_version is too old. OpenClaw requires Node.js >= 22.12"
        return 0
    fi
    
    if [ "$major" -eq 22 ] && [ "$minor" -lt 12 ]; then
        MESSAGE="Node.js version $node_version is too old. OpenClaw requires Node.js >= 22.12"
        return 0
    fi
    
    return 1
}

# --- check-plugins-sdk.sh ---
# check-plugins-sdk.sh - Detect plugin SDK compatibility issues
# Based on real-world repair of 小文 (192.168.11.219)
#
# 检测的问题:
#   1. ERR_MODULE_NOT_FOUND: plugin-sdk 模块缺失
#   2. api.config.get is not a function - API 版本不兼容
#   3. plugins.load.paths 中的无效路径

check_plugins_sdk() {
    SEVERITY="fatal"

    local doctor_out="${CLAWICU_DOCTOR_OUT:-}"
    local config_file="$HOME/.openclaw/openclaw.json"
    local ext_dir="$HOME/.openclaw/extensions"

    # --- 1. 检测 ERR_MODULE_NOT_FOUND: plugin-sdk ---
    if [ -f "$doctor_out" ]; then
        # "Cannot find module '/path/to/plugin-sdk'"
        if grep -q "Cannot find module.*plugin-sdk\|ERR_MODULE_NOT_FOUND.*plugin-sdk" "$doctor_out" 2>/dev/null; then
            local sdk_err
            sdk_err="$(grep "Cannot find module.*plugin-sdk" "$doctor_out" | head -1)"
            # 提取引用 plugin-sdk 的插件路径
            local plugin_path
            plugin_path="$(grep "imported from" "$doctor_out" 2>/dev/null | head -1 \
                | grep -o '/[^ ]*\.js')"
            
            MESSAGE="Plugin SDK module missing"
            DETAILS="A plugin imports openclaw/plugin-sdk but the module is not installed. Path: ${plugin_path:-unknown}. This usually happens after OpenClaw upgrade. Repair: reinstall plugin dependencies or disable the plugin."
            return 0
        fi

        # "api.config.get is not a function" - specific SDK API incompatibility
        if grep -q "api\.config\.get is not a function\|api\.tools\.register is not a function" "$doctor_out" 2>/dev/null; then
            local api_err
            api_err="$(grep "is not a function" "$doctor_out" | head -1 | sed 's/^[[:space:]]*//')"
            # 提取插件路径
            local plugin_path
            plugin_path="$(grep -B5 "is not a function" "$doctor_out" 2>/dev/null \
                | grep "at activate" | head -1 \
                | grep -o '(/[^)]*)' | tr -d '()' | sed 's/:[0-9]*:[0-9]*$//')"
            
            MESSAGE="Plugin SDK API incompatibility: ${api_err:-unknown API error}"
            DETAILS="Plugin at '${plugin_path:-unknown}' uses an outdated OpenClaw plugin SDK API. The plugin needs to be updated to match the current OpenClaw version, or disabled."
            return 0
        fi

        # "TypeError: ... is not a function" general plugin errors
        if grep -q "TypeError:.*is not a function\|ReferenceError:.*is not defined" "$doctor_out" 2>/dev/null; then
            # 检查是否在 activate 上下文中
            if grep -B3 "is not a function\|is not defined" "$doctor_out" 2>/dev/null | grep -q "at activate"; then
                local type_err
                type_err="$(grep "TypeError:\|ReferenceError:" "$doctor_out" | head -1 | sed 's/^[[:space:]]*//')"
                MESSAGE="Plugin runtime error during activation"
                DETAILS="${type_err:-Unknown error}. This is typically caused by API incompatibility after OpenClaw upgrade."
                return 0
            fi
        fi
    fi

    # --- 2. 检测 plugins.load.paths 中的无效路径 ---
    if [ -f "$config_file" ] && command -v jq >/dev/null 2>&1; then
        local paths
        paths=$(jq -r '.plugins.load.paths[]? // empty' "$config_file" 2>/dev/null)
        
        for path in $paths; do
            # 展开路径
            local expanded_path="${path//\~/$HOME}"
            expanded_path="${expanded_path//\$HOME/$HOME}"
            
            if [ ! -d "$expanded_path" ]; then
                MESSAGE="Invalid plugin path in config: $path"
                DETAILS="plugins.load.paths contains '$path' which does not exist. This will cause Gateway startup failure. Repair will remove this path."
                return 0
            fi
            
            # 检查路径是否指向已禁用的插件目录
            if [ -d "${expanded_path}.disabled" ] || [ -d "${expanded_path}.clawicu-disabled" ]; then
                MESSAGE="Plugin path points to disabled plugin: $path"
                DETAILS="The plugin at '$path' appears to have been disabled (disabled directory exists). Repair will remove this path from config."
                return 0
            fi
        done
    fi

    # --- 3. 检测 extensions 目录中的插件依赖问题 ---
    if [ -d "$ext_dir" ]; then
        for plugin_dir in "$ext_dir"/*/; do
            [ -d "$plugin_dir" ] || continue
            local name
            name="$(basename "$plugin_dir")"
            
            # 跳过已禁用的
            case "$name" in
                *.disabled|*.clawicu-disabled) continue ;;
            esac
            
            # 检查 node_modules 是否存在但 plugin-sdk 缺失
            if [ -f "$plugin_dir/package.json" ] && [ -d "$plugin_dir/node_modules" ]; then
                # 检查 package.json 是否依赖 plugin-sdk
                if grep -q "plugin-sdk\|@openclaw/plugin-sdk" "$plugin_dir/package.json" 2>/dev/null; then
                    if [ ! -d "$plugin_dir/node_modules/openclaw" ] && \
                       [ ! -d "$plugin_dir/node_modules/@openclaw" ]; then
                        MESSAGE="Plugin '$name' has broken plugin-sdk dependency"
                        DETAILS="Plugin at $plugin_dir declares plugin-sdk dependency but node_modules is incomplete. Run: cd '$plugin_dir' && npm install"
                        SEVERITY="warn"
                        return 0
                    fi
                fi
            fi
        done
    fi

    return 1  # No issues found
}

# --- check-plugins.sh ---
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

# --- check-port.sh ---
# check-port.sh - Detect if port 18789 is occupied by another process

check_port() {
    SEVERITY="fatal"
    
    local port="${OPENCLAW_GATEWAY_PORT:-18789}"
    
    case "$(uname -s)" in
        Darwin*)
            local listener listener_pid
            listener="$(lsof -i :"$port" -sTCP:LISTEN 2>/dev/null | tail -1 | awk '{print $1}')"
            listener_pid="$(lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null | head -1)"
            if [ -n "$listener" ]; then
                # Skip if it's openclaw gateway
                local proc_cmd
                proc_cmd="$(ps -p "$listener_pid" -o args= 2>/dev/null)"
                if echo "$proc_cmd" | grep -qi "openclaw"; then
                    return 1
                fi
                MESSAGE="Port $port is occupied by: $listener (PID $listener_pid)"
                return 0
            fi
            ;;
        Linux*)
            if command -v ss >/dev/null 2>&1; then
                if ss -tuln 2>/dev/null | grep -q ":${port}[[:space:]]"; then
                    local proc_pid
                    proc_pid="$(ss -tulnp 2>/dev/null | grep ":${port}[[:space:]]" \
                        | grep -o 'pid=[0-9]*' | head -1 | cut -d= -f2)"
                    if [ -z "$proc_pid" ]; then
                        proc_pid="$(lsof -ti ":$port" 2>/dev/null | head -1)"
                    fi
                    # If the port is used by the openclaw gateway itself, that is
                    # expected and not a conflict - skip reporting.
                    if [ -n "$proc_pid" ]; then
                        local proc_cmd
                        proc_cmd="$(ps -p "$proc_pid" -o args= 2>/dev/null || cat /proc/$proc_pid/cmdline 2>/dev/null | tr '\0' ' ')"
                        if echo "$proc_cmd" | grep -qi "openclaw"; then
                            return 1  # Port is used by openclaw gateway — normal
                        fi
                    fi
                    MESSAGE="Port $port is already in use by another process"
                    DETAILS="${proc_pid:+PID $proc_pid is blocking the port. }Run: ss -tulnp | grep :$port"
                    return 0
                fi
            elif command -v lsof >/dev/null 2>&1; then
                local listener listener_pid
                listener="$(lsof -i ":$port" -sTCP:LISTEN 2>/dev/null | tail -1 | awk '{print $1}')"
                listener_pid="$(lsof -ti ":$port" -sTCP:LISTEN 2>/dev/null | head -1)"
                if [ -n "$listener" ]; then
                    # Skip if it's openclaw
                    local proc_cmd
                    proc_cmd="$(ps -p "$listener_pid" -o args= 2>/dev/null)"
                    if echo "$proc_cmd" | grep -qi "openclaw"; then
                        return 1
                    fi
                    MESSAGE="Port $port is already in use by: $listener"
                    return 0
                fi
            fi
            ;;
    esac
    
    return 1
}

# --- check-sessions.sh ---
# check-sessions.sh - Detect corrupted session files

check_sessions() {
    SEVERITY="info"
    
    local sessions_dir="${OPENCLAW_SESSIONS_DIR:-$HOME/.openclaw/sessions}"
    
    if [ ! -d "$sessions_dir" ]; then
        return 1
    fi
    
    local corrupted=""
    for session in "$sessions_dir"/*.json; do
        [ -e "$session" ] || continue
        if ! node -e "JSON.parse(require('fs').readFileSync('$session', 'utf8'))" 2>/dev/null; then
            corrupted="$corrupted $(basename "$session")"
        fi
    done
    
    if [ -n "$corrupted" ]; then
        MESSAGE="Session files corrupted:$corrupted"
        return 0
    fi
    
    return 1
}

# --- check-state-dir.sh ---
# check-state-dir.sh - Detect if ~/.openclaw/ is missing or permissions broken

check_state_dir() {
    SEVERITY="fatal"
    
    local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
    
    if [ ! -d "$state_dir" ]; then
        MESSAGE="OpenClaw state directory missing: $state_dir"
        return 0
    fi
    
    if [ ! -r "$state_dir" ] || [ ! -w "$state_dir" ]; then
        MESSAGE="OpenClaw state directory has incorrect permissions: $state_dir"
        return 0
    fi
    
    return 1
}

# --- check-version-mismatch.sh ---
# check-version-mismatch.sh - Detect CLI/Gateway version mismatch
# Based on real-world repair of 小文 (192.168.11.219)
#
# 问题: npm install 后 CLI 是 2026.4.5，但 Gateway 显示 2026.4.2
# 原因: Gateway 没有重启，还在用旧版本
# 检测: 比较运行中的 Gateway 版本和安装的 CLI 版本

check_version_mismatch() {
    SEVERITY="warn"
    
    local cli_version
    local gateway_version
    
    # 1. 获取 CLI 版本
    if command -v openclaw >/dev/null 2>&1; then
        cli_version=$(openclaw --version 2>/dev/null | grep -oE '[0-9]{4}\.[0-9]+\.[0-9]+' | head -1)
    else
        return 1  # openclaw binary not found
    fi
    
    [ -n "$cli_version" ] || return 1
    
    # 2. 获取 Gateway 版本
    # 方法 1: 从 systemd 服务状态
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl --user is-active openclaw-gateway >/dev/null 2>&1; then
            gateway_version=$(systemctl --user status openclaw-gateway --no-pager 2>/dev/null \
                | grep -oE 'v[0-9]{4}\.[0-9]+\.[0-9]+' | head -1 | tr -d 'v')
        fi
    fi
    
    # 方法 2: 从进程列表
    if [ -z "$gateway_version" ]; then
        gateway_version=$(ps aux 2>/dev/null | grep "[o]penclaw-gatewa" \
            | grep -oE 'v[0-9]{4}\.[0-9]+\.[0-9]+' | head -1 | tr -d 'v')
    fi
    
    # 方法 3: 从日志文件
    if [ -z "$gateway_version" ]; then
        local log_file="$HOME/.openclaw/logs/openclaw-$(date +%Y-%m-%d).log"
        if [ -f "$log_file" ]; then
            gateway_version=$(grep -h "OpenClaw Gateway" "$log_file" 2>/dev/null | tail -1 \
                | grep -oE 'v[0-9]{4}\.[0-9]+\.[0-9]+' | head -1 | tr -d 'v')
        fi
    fi
    
    # 方法 4: 从 /tmp 日志
    if [ -z "$gateway_version" ]; then
        gateway_version=$(grep -rh "OpenClaw Gateway" /tmp/openclaw/*.log 2>/dev/null | tail -1 \
            | grep -oE 'v[0-9]{4}\.[0-9]+\.[0-9]+' | head -1 | tr -d 'v')
    fi
    
    # 3. 比较版本
    if [ -n "$gateway_version" ]; then
        if [ "$cli_version" != "$gateway_version" ]; then
            MESSAGE="Version mismatch: CLI=$cli_version, Gateway=$gateway_version"
            DETAILS="Gateway is running an older version than installed CLI. Restart with: systemctl --user restart openclaw-gateway"
            return 0
        fi
    fi
    
    return 1  # No version mismatch
}

# --- check-version.sh ---
# check-version.sh - Detect unsupported OpenClaw version

check_version() {
    SEVERITY="warn"
    
    if ! command -v openclaw >/dev/null 2>&1; then
        return 1
    fi
    
    local version="$(openclaw --version 2>/dev/null | sed 's/openclaw //' | tr -d 'v')"
    
    if [ -z "$version" ]; then
        MESSAGE="Could not determine OpenClaw version"
        return 0
    fi
    
    local major="$(echo "$version" | cut -d. -f1)"
    local minor="$(echo "$version" | cut -d. -f2)"
    
    if [ "$major" -lt 1 ] 2>/dev/null; then
        MESSAGE="OpenClaw version $version is no longer supported"
        return 0
    fi
    
    return 1
}

# === REPAIR MODULES ===

# --- repair-channel-policy.sh ---
# repair-channel-policy.sh - Fix channel configuration issues
# Based on real-world repair of 小文 (192.168.11.219)
#
# 问题: groupPolicy='allowlist' 导致私信不响应
# 解决方案: 将 groupPolicy 改为 'open'

repair_channel_policy() {
    describe() {
        echo "Adjust Discord channel policy to allow direct messages"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Change channels.discord.groupPolicy to 'open'"
        echo "  - Backup config before modification"
        echo "  - Restart gateway to apply changes"
    }

    execute() {
        log_info "Starting channel policy repair..."

        local config_file="$HOME/.openclaw/openclaw.json"
        [ -f "$config_file" ] || { log_warn "Config file not found"; return 1; }

        # 检查是否需要修复
        local current_policy
        current_policy=$(jq -r '.channels.discord.groupPolicy // empty' "$config_file" 2>/dev/null)
        
        if [ "$current_policy" != "allowlist" ]; then
            log_info "Current groupPolicy is '$current_policy', no fix needed"
            return 0
        fi

        log_info "Changing groupPolicy from 'allowlist' to 'open'..."

        # 备份
        backup_create "repair-channel-policy" >/dev/null

        # 修改配置
        if command -v jq >/dev/null 2>&1; then
            local tmp_file
            tmp_file=$(mktemp)
            
            if jq '.channels.discord.groupPolicy = "open"' "$config_file" > "$tmp_file"; then
                mv "$tmp_file" "$config_file"
                log_info "Changed groupPolicy to 'open'"
                printf "   [OK] Discord groupPolicy updated to 'open'\n"
            else
                rm -f "$tmp_file"
                log_error "Failed to update config"
                return 1
            fi
        else
            log_warn "jq not available, cannot auto-fix"
            printf "   [!] Manual fix: edit %s and change groupPolicy to 'open'\n" "$config_file"
            return 1
        fi

        # 提示重启
        log_info "Restart gateway to apply changes: systemctl --user restart openclaw-gateway"
        printf "   [i] Restart required: systemctl --user restart openclaw-gateway\n"

        return 0
    }
}

# --- repair-config-field.sh ---
# repair-config-field.sh - Reset individual OpenClaw config fields to defaults
#
# OpenClaw config is at ~/.openclaw/openclaw.json (JSON5 format).
# Config fields use dot-notation paths, e.g. gateway.port, gateway.bind.
# The preferred method is 'openclaw config set <path> <value>'.
# Python3 / Node.js are used as fallbacks when the binary is unavailable.



repair_config_field() {
    # Known resettable fields: dot-notation path -> default value
    # Values are strings; numeric/boolean types are cast by the setter.
    _field_defaults() {
        case "$1" in
            gateway.port)      echo "18789" ;;
            gateway.bind)      echo "loopback" ;;
            gateway.mode)      echo "local" ;;
            gateway.auth.mode) echo "token" ;;
            agents.defaults.workspace) echo "~/.openclaw/workspace" ;;
            *)                 echo "" ;;
        esac
    }

    _known_fields() {
        echo "gateway.port       - Gateway WebSocket port (default: 18789)"
        echo "gateway.bind       - Bind mode: loopback|lan|auto|tailnet (default: loopback)"
        echo "gateway.mode       - Gateway mode (default: local)"
        echo "gateway.auth.mode  - Auth mode: token|password|none (default: token)"
        echo "agents.defaults.workspace - Agent workspace path (default: ~/.openclaw/workspace)"
    }

    describe() {
        echo "Reset individual OpenClaw config fields to their default values"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Back up current config"
        echo "  - Reset the specified field to its default value"
        echo "  - Verify config is still valid JSON5"
        echo "  - Roll back if verification fails"
        echo ""
        echo "Known resettable fields:"
        _known_fields
    }

    _validate_json5() {
        local cfg="$1"
        [ -f "$cfg" ] || return 1
        local size
        size=$(wc -c < "$cfg" 2>/dev/null || echo 0)
        [ "$size" -eq 0 ] && return 1

        # Prefer openclaw's own validation if the binary is available
        if command -v openclaw >/dev/null 2>&1; then
            openclaw config validate 2>/dev/null && return 0
        fi

        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import re, json, sys
txt = open(sys.argv[1]).read()
txt = re.sub(r'//.*', '', txt)
txt = re.sub(r'/\*.*?\*/', '', txt, flags=re.DOTALL)
txt = re.sub(r',\s*([}\]])', r'\1', txt)
json.loads(txt)
" "$cfg" 2>/dev/null && return 0
        fi

        if command -v node >/dev/null 2>&1; then
            node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$cfg" 2>/dev/null && return 0
        fi

        grep -q '{' "$cfg" 2>/dev/null && return 0
        return 1
    }

    # Set a dot-notation config path to a value.
    # Preferred: 'openclaw config set <path> <value>'
    # Fallback: Python3 with nested key traversal, then Node.js.
    _set_field() {
        local cfg="$1"
        local field="$2"    # dot-notation: e.g. gateway.port
        local value="$3"

        # Best: delegate to the official CLI (handles JSON5 format and schema)
        if command -v openclaw >/dev/null 2>&1; then
            openclaw config set "$field" "$value" 2>/dev/null && return 0
        fi

        # Fallback: Python3 with dot-notation path traversal
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import re, json, sys

def set_nested(d, path, val):
    keys = path.split('.')
    for k in keys[:-1]:
        if k not in d or not isinstance(d[k], dict):
            d[k] = {}
        d = d[k]
    # Cast numeric and boolean values
    if val.isdigit():
        val = int(val)
    elif val == 'true':
        val = True
    elif val == 'false':
        val = False
    d[keys[-1]] = val

path_arg, field_arg, val_arg = sys.argv[1], sys.argv[2], sys.argv[3]
txt = open(path_arg).read()
# Strip JS-style comments and trailing commas for parsing
txt = re.sub(r'//.*', '', txt)
txt = re.sub(r'/\*.*?\*/', '', txt, flags=re.DOTALL)
txt = re.sub(r',\s*([}\]])', r'\1', txt)
d = json.loads(txt)
set_nested(d, field_arg, val_arg)
with open(path_arg, 'w') as f:
    json.dump(d, f, indent=2)
" "$cfg" "$field" "$value" 2>/dev/null && return 0
        fi

        # Fallback: Node.js with dot-notation path traversal
        if command -v node >/dev/null 2>&1; then
            node -e "
const fs = require('fs');
const [cfgPath, fieldPath, rawVal] = process.argv.slice(1);
const obj = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
const keys = fieldPath.split('.');
let cur = obj;
for (let i = 0; i < keys.length - 1; i++) {
    if (!cur[keys[i]] || typeof cur[keys[i]] !== 'object') cur[keys[i]] = {};
    cur = cur[keys[i]];
}
const last = keys[keys.length - 1];
cur[last] = /^\d+\$/.test(rawVal) ? Number(rawVal)
          : rawVal === 'true'  ? true
          : rawVal === 'false' ? false
          : rawVal;
fs.writeFileSync(cfgPath, JSON.stringify(obj, null, 2));
" "$cfg" "$field" "$value" 2>/dev/null && return 0
        fi

        log_fatal "Need openclaw, python3, or node to modify config fields"
        return 1
    }

    execute() {
        log_info "Starting config field reset repair..."

        # OpenClaw config: ~/.openclaw/openclaw.json
        local config_dir="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
        local config_file="$config_dir/openclaw.json"

        # Accept legacy .json5 extension
        [ ! -f "$config_file" ] && config_file="$config_dir/openclaw.json5"

        if [ ! -f "$config_file" ]; then
            log_fatal "Cannot find config file: $config_dir/openclaw.json"
            return 1
        fi

        local field="${OPENCLAW_RESET_FIELD:-}"
        if [ -z "$field" ]; then
            log_info "Available fields to reset:"
            _known_fields
            log_fatal "Set OPENCLAW_RESET_FIELD env var to the field path (e.g. gateway.port)"
            return 1
        fi

        local default_val
        default_val="$(_field_defaults "$field")"
        if [ -z "$default_val" ]; then
            log_fatal "Unknown field: $field"
            log_info "Known fields:"
            _known_fields
            return 1
        fi

        log_info "Resetting '$field' -> '$default_val'"

        # Direct config file snapshot for rollback (backup_create returns a
        # tar.gz of the state dir and cannot be cp'd back as a config file).
        local config_snapshot="${config_file}.clawicu-$(date '+%Y%m%d-%H%M%S').bak"
        cp "$config_file" "$config_snapshot"
        log_info "Config snapshot saved: $config_snapshot"

        backup_create "repair-config-field" >/dev/null
        state_push "repair-config-field"

        if ! _set_field "$config_file" "$field" "$default_val"; then
            log_error "Failed to set field, rolling back..."
            cp "$config_snapshot" "$config_file"
            rm -f "$config_snapshot"
            state_rollback
            return 1
        fi

        if _validate_json5 "$config_file"; then
            rm -f "$config_snapshot"
            log_info "Field '$field' reset to '$default_val' successfully"
            return 0
        else
            log_error "Config validation failed after field reset, rolling back..."
            cp "$config_snapshot" "$config_file"
            rm -f "$config_snapshot"
            state_rollback
            return 1
        fi
    }
}

# --- repair-config.sh ---
# repair-config.sh - Restore OpenClaw config from a backup


# Source dependencies

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
        # backup_create() produces a tar.gz of the state dir - cannot be
        # cp'd directly back as a config file, so we keep a separate snapshot.
        local config_snapshot="${config_file}.clawicu-$(date '+%Y%m%d-%H%M%S').bak"
        cp "$config_file" "$config_snapshot"
        log_info "Config snapshot saved: $config_snapshot"

        # Full state backup (discard path - not used for cp rollback)
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

# --- repair-credentials.sh ---
# repair-credentials.sh - Detect and prompt for missing provider credentials


# Source dependencies

repair_credentials() {
    describe() {
        echo "Detect and prompt for missing provider API credentials"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Scan for known provider credential files"
        echo "  - Detect which providers are missing API keys"
        echo "  - Prompt user for each missing key (input hidden)"
        echo "  - Write credentials to ~/.openclaw/credentials/<provider>.env"
        echo "  - Verify each credential file was written correctly"
    }

    # Known providers and their env var names
    _known_providers() {
        echo "openai:OPENAI_API_KEY"
        echo "anthropic:ANTHROPIC_API_KEY"
        echo "google:GOOGLE_API_KEY"
        echo "mistral:MISTRAL_API_KEY"
        echo "groq:GROQ_API_KEY"
        echo "cohere:COHERE_API_KEY"
    }

    # Check if a provider credential already exists and is non-empty
    # Args: $1 = provider name
    _credential_exists() {
        local provider="$1"
        local cred_dir="${OPENCLAW_CRED_DIR:-$HOME/.openclaw/credentials}"
        local cred_file="$cred_dir/$provider.env"

        if [ -f "$cred_file" ]; then
            # Check if file has a non-empty value
            local value
            value=$(grep -v '^[[:space:]]*$' "$cred_file" | grep -v '^[[:space:]]*#' | head -1)
            if [ -n "$value" ]; then
                return 0
            fi
        fi
        return 1
    }

    # Prompt for a credential securely (no echo)
    # Args: $1 = provider name, $2 = env var name
    # Outputs: the env file line to store
    _prompt_credential() {
        local provider="$1"
        local env_var="$2"

        printf "Enter API key for %s (%s): " "$provider" "$env_var" >&2
        # Use stty to suppress echo for security
        local key
        if [ -t 0 ]; then
            stty -echo 2>/dev/null || true
            read -r key
            stty echo 2>/dev/null || true
            echo "" >&2
        else
            read -r key
        fi

        if [ -z "$key" ]; then
            log_warn "No key provided for $provider, skipping"
            return 1
        fi

        echo "${env_var}=${key}"
        return 0
    }

    # Verify credential file exists and is readable
    # Args: $1 = provider name
    _verify_credential() {
        local provider="$1"
        local cred_dir="${OPENCLAW_CRED_DIR:-$HOME/.openclaw/credentials}"
        local cred_file="$cred_dir/$provider.env"

        if [ ! -f "$cred_file" ]; then
            return 1
        fi

        # Ensure file has correct permissions (owner-only)
        chmod 600 "$cred_file" 2>/dev/null || true

        # Verify non-empty
        local content
        content=$(grep -v '^[[:space:]]*$' "$cred_file" | grep -v '^[[:space:]]*#')
        [ -n "$content" ]
    }

    execute() {
        log_info "Starting credentials repair..."

        local cred_dir="${OPENCLAW_CRED_DIR:-$HOME/.openclaw/credentials}"
        local missing_count=0
        local fixed_count=0
        local failed_providers=""

        # Ensure credentials directory exists with restrictive permissions
        mkdir -p "$cred_dir"
        chmod 700 "$cred_dir" 2>/dev/null || true

        backup_create "repair-credentials"
        state_push "repair-credentials"

        # Use here-doc instead of pipe so the while loop runs in the current
        # shell - a pipe would create a subshell and variable updates
        # (missing_count, fixed_count, failed_providers) would be lost.
        while IFS=: read -r provider env_var; do
            [ -z "$provider" ] && continue
            if _credential_exists "$provider"; then
                log_info "Credential for $provider: OK"
                continue
            fi

            missing_count=$((missing_count + 1))
            log_warn "Missing credential for $provider"

            # Prompt for the key
            local cred_line
            cred_line=$(_prompt_credential "$provider" "$env_var") || continue

            if [ -n "$cred_line" ]; then
                local cred_file="$cred_dir/$provider.env"
                echo "# $provider credentials - $(date '+%Y-%m-%d')" > "$cred_file"
                echo "$cred_line" >> "$cred_file"
                chmod 600 "$cred_file"

                if _verify_credential "$provider"; then
                    log_info "Credential for $provider saved successfully"
                    fixed_count=$((fixed_count + 1))
                else
                    log_warn "Failed to verify credential for $provider"
                    failed_providers="$failed_providers $provider"
                fi
            fi
        done <<PROVIDERS
$(_known_providers)
PROVIDERS

        if [ -n "$failed_providers" ]; then
            log_warn "Some credentials could not be verified:$failed_providers"
            state_rollback
            return 1
        fi

        # If credentials were missing but the user skipped all prompts, report failure
        if [ "$missing_count" -gt 0 ] && [ "$fixed_count" -eq 0 ]; then
            log_warn "No credentials were saved (all prompts skipped)"
            return 1
        fi

        log_info "Credentials repair completed"
        return 0
    }
}

# --- repair-daemon.sh ---
# repair-daemon.sh - Reinstall launchd (macOS) or systemd user service (Linux)
#
# OpenClaw installs a user-level daemon via 'openclaw daemon install':
#   macOS:  LaunchAgent plist under ~/Library/LaunchAgents/
#   Linux:  systemd user service (~/.config/systemd/user/) - NO root required
#
# This repair script uses 'openclaw daemon' subcommands to reinstall the service
# correctly, rather than generating plist/unit files manually.



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

# --- repair-docker.sh ---
# repair-docker.sh - Restart and recreate Docker container and volumes


# Source dependencies

repair_docker() {
    describe() {
        echo "Restart OpenClaw Docker container with optional volume recreation"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Check if OpenClaw is running in a Docker container"
        echo "  - Detect container runtime (Docker or Podman)"
        echo "  - Stop the container gracefully"
        echo "  - Capture current container config (env, ports, volumes)"
        echo "  - Remove the container (image preserved)"
        echo "  - Optionally recreate volumes"
        echo "  - Recreate container with same configuration"
        echo "  - Start container and verify gateway responds"
    }

    # Default container name
    _container_name() {
        echo "${OPENCLAW_CONTAINER_NAME:-openclaw}"
    }

    # Detect container runtime
    _detect_runtime() {
        if command -v docker >/dev/null 2>&1; then
            echo "docker"
        elif command -v podman >/dev/null 2>&1; then
            echo "podman"
        else
            echo ""
        fi
    }

    # Check if container exists
    # Args: $1 = runtime, $2 = container name
    _container_exists() {
        local runtime="$1"
        local name="$2"
        "$runtime" ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${name}$"
    }

    # Check if container is running
    # Args: $1 = runtime, $2 = container name
    _container_running() {
        local runtime="$1"
        local name="$2"
        "$runtime" ps --format '{{.Names}}' 2>/dev/null | grep -q "^${name}$"
    }

    # Capture container configuration for recreation
    # Args: $1 = runtime, $2 = container name
    # Outputs key config elements
    _capture_config() {
        local runtime="$1"
        local name="$2"

        local inspect_out
        inspect_out=$("$runtime" inspect "$name" 2>/dev/null || echo "[]")

        # Extract image
        local image
        image=$(echo "$inspect_out" | grep -o '"Image": *"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')
        echo "IMAGE=$image"

        # Extract port bindings
        local host_port
        host_port=$(echo "$inspect_out" | grep -o '"HostPort": *"[0-9]*"' | head -1 | grep -o '[0-9]*')
        local container_port
        container_port=$(echo "$inspect_out" | grep -o '"Destination": *"[0-9]*"' | head -1 | grep -o '[0-9]*')
        if [ -z "$container_port" ]; then
            container_port="18789"
        fi
        echo "HOST_PORT=${host_port:-18789}"
        echo "CONTAINER_PORT=${container_port}"

        # Extract env vars
        local env_vars
        env_vars=$(echo "$inspect_out" | grep -o '"Env": *\[[^\]]*\]' | head -1)
        echo "HAS_ENV=$([ -n "$env_vars" ] && echo yes || echo no)"

        # Extract volume mounts
        local volumes
        volumes=$("$runtime" inspect "$name" --format '{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}' 2>/dev/null || true)
        echo "VOLUMES=$volumes"
    }

    # Stop container gracefully
    # Args: $1 = runtime, $2 = container name
    _stop_container() {
        local runtime="$1"
        local name="$2"

        log_info "Stopping container $name..."
        "$runtime" stop "$name" 2>/dev/null || true
        sleep 2

        # Force stop if still running
        if _container_running "$runtime" "$name"; then
            log_warn "Container did not stop gracefully, force stopping..."
            "$runtime" kill "$name" 2>/dev/null || true
            sleep 2
        fi
    }

    # Recreate container with captured config
    # Args: $1 = runtime, $2 = container name, $3 = image, $4 = host port, $5 = volumes
    _recreate_container() {
        local runtime="$1"
        local name="$2"
        local image="$3"
        local host_port="$4"
        local volumes="$5"

        # Build the argument list using positional parameters so each argument
        # is passed as a distinct word - avoids word-splitting on paths with spaces.
        set -- -d --name "$name" -p "${host_port}:18789"

        # Add volume mounts if present
        if [ -n "$volumes" ]; then
            for vol in $volumes; do
                set -- "$@" -v "$vol"
            done
        fi

        log_info "Creating new container: $runtime run $* $image"
        "$runtime" run "$@" "$image" 2>&1
    }

    # Verify gateway responds
    # Args: $1 = host port
    _verify_gateway() {
        local port="$1"
        local max_retries=10
        local retry=0

        log_info "Waiting for gateway on port $port..."

        while [ "$retry" -lt "$max_retries" ]; do
            retry=$((retry + 1))
            sleep 2

            if command -v curl >/dev/null 2>&1; then
                if curl -s -o /dev/null -w '' "http://127.0.0.1:$port/health" 2>/dev/null; then
                    log_info "Gateway responded on port $port"
                    return 0
                fi
            elif command -v wget >/dev/null 2>&1; then
                if wget -q -O /dev/null "http://127.0.0.1:$port/health" 2>/dev/null; then
                    log_info "Gateway responded on port $port"
                    return 0
                fi
            fi

            log_debug "Retry $retry/$max_retries..."
        done

        log_warn "Gateway did not respond after $max_retries retries"
        return 1
    }

    execute() {
        log_info "Starting Docker repair..."

        # Detect runtime
        local runtime
        runtime=$(_detect_runtime)

        if [ -z "$runtime" ]; then
            log_fatal "No container runtime found (Docker or Podman required)"
            return 1
        fi

        log_info "Using runtime: $runtime"

        local cname
        cname=$(_container_name)

        # Check if container exists
        if ! _container_exists "$runtime" "$cname"; then
            log_warn "Container '$cname' not found"
            log_info "Checking for any OpenClaw container..."

            # Try to find any openclaw container
            local found
            found=$("$runtime" ps -a --format '{{.Names}}' 2>/dev/null | grep -i openclaw | head -1 || true)
            if [ -n "$found" ]; then
                cname="$found"
                log_info "Found container: $cname"
            else
                log_fatal "No OpenClaw container found"
                return 1
            fi
        fi

        backup_create "repair-docker"
        state_push "repair-docker"

        # Capture current config before stopping
        log_info "Capturing container configuration..."
        local config
        config=$(_capture_config "$runtime" "$cname")
        echo "$config"

        local image=""
        local host_port="18789"
        local volumes=""

        # Parse captured config
        echo "$config" | while IFS='=' read -r key value; do
            case "$key" in
                IMAGE) image="$value" ;;
                HOST_PORT) host_port="$value" ;;
                VOLUMES) volumes="$value" ;;
            esac
        done

        # Re-read config since subshell vars don't persist
        image=$(echo "$config" | grep '^IMAGE=' | cut -d= -f2)
        host_port=$(echo "$config" | grep '^HOST_PORT=' | cut -d= -f2)
        volumes=$(echo "$config" | grep '^VOLUMES=' | cut -d= -f2-)

        if [ -z "$image" ]; then
            log_fatal "Could not determine container image"
            return 1
        fi

        log_info "Image: $image, Port: $host_port"

        # Ask about volume recreation
        local recreate_volumes="no"
        printf "Recreate volumes? This will DELETE volume data [y/N]: " >&2
        read -r vol_answer
        case "$vol_answer" in
            [yY]|[yY][eE][sS]) recreate_volumes="yes" ;;
        esac

        # Stop container
        _stop_container "$runtime" "$cname"

        # Remove container (preserving image)
        log_info "Removing container $cname..."
        "$runtime" rm "$cname" 2>/dev/null || true

        # Recreate volumes if requested
        if [ "$recreate_volumes" = "yes" ]; then
            log_warn "Recreating volumes (data will be lost)..."
            local vol_names
            vol_names=$("$runtime" volume ls -q 2>/dev/null | grep openclaw || true)
            for vol in $vol_names; do
                log_info "Removing volume: $vol"
                "$runtime" volume rm "$vol" 2>/dev/null || true
            done
        fi

        # Recreate container
        if ! _recreate_container "$runtime" "$cname" "$image" "$host_port" "$volumes"; then
            log_fatal "Failed to recreate container"
            return 1
        fi

        # Verify
        if _verify_gateway "$host_port"; then
            log_info "Docker repair completed successfully"
            return 0
        else
            log_warn "Container recreated but gateway not responding yet"
            log_info "Check container logs: $runtime logs $cname"
            return 1
        fi
    }
}

# --- repair-downgrade.sh ---
# repair-downgrade.sh - Downgrade OpenClaw to a stable version


# Source dependencies

repair_downgrade() {
    describe() {
        echo "Downgrade OpenClaw to a previous stable version"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Detect current OpenClaw version"
        echo "  - Prompt for target version or detect latest stable"
        echo "  - Create full backup of current installation"
        echo "  - Uninstall current version"
        echo "  - Install the target version via npm"
        echo "  - Verify the installed version matches target"
        echo "  - Roll back on failure"
    }

    # Get current version
    _current_version() {
        if command -v openclaw >/dev/null 2>&1; then
            openclaw --version 2>/dev/null || echo "unknown"
        else
            echo "not-installed"
        fi
    }

    # Get latest stable version from npm
    _latest_stable() {
        if command -v npm >/dev/null 2>&1; then
            npm view openclaw versions --json 2>/dev/null \
                | tail -5 \
                | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+"' \
                | tr -d '"' \
                | tail -1
        else
            echo ""
        fi
    }

    # Prompt user for target version
    # Args: $1 = current version
    _prompt_version() {
        local current="$1"
        local stable
        stable=$(_latest_stable)

        printf "Current version: %s\n" "$current" >&2
        if [ -n "$stable" ]; then
            printf "Latest stable:   %s\n" "$stable" >&2
        fi
        printf "Enter target version to downgrade to: " >&2

        read -r target
        echo "$target"
    }

    # Install a specific version
    # Args: $1 = version string
    _install_version() {
        local version="$1"

        if ! command -v npm >/dev/null 2>&1; then
            log_fatal "npm is required for downgrade but not found"
            return 1
        fi

        log_info "Installing openclaw@$version..."
        npm install -g "openclaw@$version" 2>&1
        return $?
    }

    # Verify installed version matches target
    # Args: $1 = expected version
    _verify_version() {
        local expected="$1"
        local actual
        actual=$(_current_version)

        if [ "$actual" = "$expected" ]; then
            return 0
        fi

        # Handle version prefix differences (v1.0.0 vs 1.0.0)
        case "$actual" in
            "v$expected") return 0 ;;
        esac
        case "$expected" in
            "v$actual") return 0 ;;
        esac

        log_warn "Version mismatch: expected $expected, got $actual"
        return 1
    }

    execute() {
        log_info "Starting downgrade repair..."

        # Check prerequisites
        if ! command -v npm >/dev/null 2>&1; then
            log_fatal "npm is required for downgrade. Please install Node.js first."
            return 1
        fi

        local current_version
        current_version=$(_current_version)
        log_info "Current version: $current_version"

        if [ "$current_version" = "not-installed" ]; then
            log_warn "OpenClaw is not currently installed. Use repair-reinstall instead."
            return 1
        fi

        # Determine target version
        local target_version="${OPENCLAW_DOWNGRADE_VERSION:-}"

        if [ -z "$target_version" ]; then
            target_version=$(_prompt_version "$current_version")
        fi

        if [ -z "$target_version" ]; then
            log_fatal "No target version specified"
            return 1
        fi

        log_info "Target version: $target_version"

        if [ "$current_version" = "$target_version" ]; then
            log_info "Already at target version, nothing to do"
            return 0
        fi

        # Create backup before downgrade
        local backup_path
        backup_path="$(backup_create "repair-downgrade")"
        log_info "Backup created: $backup_path"
        state_push "repair-downgrade"

        # Perform downgrade
        if _install_version "$target_version"; then
            log_info "Installation completed"
        else
            log_warn "Installation failed, attempting rollback..."
            _install_version "$current_version" || true
            state_rollback
            log_fatal "Downgrade failed, attempted rollback to $current_version"
            return 1
        fi

        # Verify
        if _verify_version "$target_version"; then
            log_info "Downgrade to $target_version completed successfully"
            return 0
        else
            log_warn "Verification failed, rolling back..."
            _install_version "$current_version" || true
            state_rollback
            return 1
        fi
    }
}

# --- repair-gateway.sh ---
# repair-gateway.sh - Restart the OpenClaw gateway process



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

# --- repair-nuclear.sh ---
# repair-nuclear.sh - Full state reset preserving credentials (HIGH RISK)


# Source dependencies

repair_nuclear() {
    describe() {
        echo "FULL STATE RESET - Preserve only credentials, reset everything else (HIGH RISK)"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - *** WARNING: THIS IS A DESTRUCTIVE OPERATION ***"
        echo "  - Create comprehensive backup of entire ~/.openclaw/"
        echo "  - Backup credentials directory separately"
        echo "  - Remove ALL state except credentials/"
        echo "  - Remove sessions, plugins, config, logs, cache"
        echo "  - Reinitialize with fresh default config"
        echo "  - Restore credentials from backup"
        echo "  - You will need to reconfigure everything else"
    }

    # Print extensive warning and require confirmation
    _warn_and_confirm() {
        echo "" >&2
        log_warn "=============================================="
        log_warn "  *** HIGH RISK OPERATION ***"
        log_warn "=============================================="
        log_warn ""
        log_warn "This will RESET your entire OpenClaw state:"
        log_warn "  - ALL sessions will be destroyed"
        log_warn "  - ALL plugins will be removed"
        log_warn "  - ALL configuration will be reset to defaults"
        log_warn "  - ALL logs and cache will be cleared"
        log_warn ""
        log_warn "Only your API credentials will be preserved."
        log_warn ""
        log_warn "A full backup will be created, but this is"
        log_warn "still the most aggressive repair available."
        log_warn ""
        log_warn "=============================================="
        printf "Type 'NUCLEAR-RESET' to proceed: " >&2

        read -r confirmation
        if [ "$confirmation" != "NUCLEAR-RESET" ]; then
            log_info "Nuclear reset cancelled by user"
            return 1
        fi
        return 0
    }

    # Backup credentials separately for safety
    _backup_credentials() {
        local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
        local cred_dir="$state_dir/credentials"
        local cred_backup="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/credentials-backup-$(date '+%Y%m%d-%H%M%S')"

        if [ -d "$cred_dir" ]; then
            cp -r "$cred_dir" "$cred_backup"
            chmod 700 "$cred_backup" 2>/dev/null || true
            echo "$cred_backup"
        else
            echo ""
        fi
    }

    # Remove all state except credentials
    _nuke_state() {
        local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

        for item in "$state_dir"/*; do
            [ -e "$item" ] || continue
            local name
            name=$(basename "$item")

            case "$name" in
                credentials)
                    # Preserve credentials
                    log_info "Preserving: $name/"
                    ;;
                credentials-backup-*)
                    # Preserve credential backups
                    log_info "Preserving: $name/"
                    ;;
                backups)
                    # Preserve backups for rollback
                    log_info "Preserving: $name/"
                    ;;
                *)
                    log_info "Removing: $name"
                    rm -rf "$item"
                    ;;
            esac
        done
    }

    # Reinitialize with fresh defaults
    _reinitialize() {
        local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

        # Create directory structure
        mkdir -p "$state_dir/sessions"
        mkdir -p "$state_dir/plugins"
        mkdir -p "$state_dir/logs"
        mkdir -p "$state_dir/cache"

        # Create minimal default config
        cat > "$state_dir/config.json5" <<'DEFCONFIG'
{
  // OpenClaw Configuration - Reset to defaults
  // Re-run openclaw setup to configure providers
  "version": "1.0.0",
  "gateway": {
    "port": 18789,
    "host": "127.0.0.1"
  },
  "providers": {},
  "plugins": []
}
DEFCONFIG

        log_info "Fresh config initialized"
    }

    execute() {
        log_info "Starting NUCLEAR repair..."
        log_warn "This is a HIGH RISK operation"

        # Require explicit confirmation
        if ! _warn_and_confirm; then
            return 1
        fi

        local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

        if [ ! -d "$state_dir" ]; then
            log_warn "State directory does not exist: $state_dir"
            log_info "Nothing to nuke, creating fresh state"
            mkdir -p "$state_dir"
            _reinitialize
            return 0
        fi

        # Create comprehensive backup
        log_info "Creating comprehensive backup..."
        local backup_path
        backup_path="$(backup_create "repair-nuclear")"
        log_info "Full backup created: $backup_path"

        state_push "repair-nuclear"

        # Backup credentials separately
        local cred_backup
        cred_backup=$(_backup_credentials)
        if [ -n "$cred_backup" ]; then
            log_info "Credentials backed up to: $cred_backup"
        else
            log_warn "No credentials directory found to preserve"
        fi

        # Nuke everything except credentials and backups
        log_warn "Removing all state (preserving credentials)..."
        _nuke_state

        # Reinitialize with fresh config
        log_info "Reinitializing with fresh defaults..."
        _reinitialize

        # Verify credentials survived
        if [ -d "$state_dir/credentials" ]; then
            local cred_count
            cred_count=$(ls "$state_dir/credentials/" 2>/dev/null | wc -l | tr -d ' ')
            log_info "Credentials preserved: $cred_count file(s)"
        fi

        log_info "Nuclear reset completed"
        log_warn "You will need to reconfigure OpenClaw (providers, plugins, etc.)"
        log_info "A full backup is available at: $backup_path"
        return 0
    }
}

# --- repair-plugins-paths.sh ---
# repair-plugins-paths.sh - Clean up invalid plugin load paths
# Based on real-world repair of 小文 (192.168.11.219)
# 
# 问题: plugins.load.paths 包含无效路径导致 Gateway 启动失败
# 解决方案:
#   1. 检查每个路径是否存在
#   2. 从 plugins.load.paths 中移除无效路径
#   3. 备份配置

repair_plugins_paths() {
    describe() {
        echo "Remove invalid paths from plugins.load.paths configuration"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Parse plugins.load.paths from openclaw.json"
        echo "  - Check each path exists"
        echo "  - Remove non-existent paths from config"
        echo "  - Backup config before modification"
    }

    execute() {
        log_info "Starting plugin paths cleanup..."

        local config_file="$HOME/.openclaw/openclaw.json"
        [ -f "$config_file" ] || { log_warn "Config file not found"; return 0; }

        # 检查是否有 jq
        if ! command -v jq >/dev/null 2>&1; then
            log_warn "jq not available, cannot auto-fix plugin paths"
            printf "   [!] Manual fix: install jq or edit %s manually\n" "$config_file"
            return 1
        fi

        # 检查是否有 paths 配置
        local has_paths
        has_paths=$(jq 'has("plugins") and .plugins.load.paths and (.plugins.load.paths | length > 0)' "$config_file" 2>/dev/null)
        [ "$has_paths" = "true" ] || { log_info "No plugins.load.paths to check"; return 0; }

        # 获取所有路径
        local paths
        paths=$(jq -r '.plugins.load.paths[]? // empty' "$config_file" 2>/dev/null)

        if [ -z "$paths" ]; then
            log_info "plugins.load.paths is empty"
            return 0
        fi

        # 检查每个路径
        local invalid_paths=""
        local valid_paths="[]"
        local count=0
        
        for path in $paths; do
            count=$((count + 1))
            # 展开路径
            local expanded="${path//\~/$HOME}"
            expanded="${expanded//\$HOME/$HOME}"
            
            if [ ! -d "$expanded" ]; then
                invalid_paths="$invalid_paths $path"
                log_warn "Invalid path found: $path"
            else
                # 保留有效路径
                valid_paths=$(echo "$valid_paths" | jq --arg p "$path" '. + [$p]')
            fi
        done

        if [ -z "$invalid_paths" ]; then
            log_info "All $count plugin paths are valid"
            return 0
        fi

        # 备份
        backup_create "repair-plugins-paths" >/dev/null

        # 更新配置
        log_info "Removing invalid paths from config..."
        
        local tmp_file
        tmp_file=$(mktemp)
        
        if jq --argjson paths "$valid_paths" '.plugins.load.paths = $paths' "$config_file" > "$tmp_file"; then
            mv "$tmp_file" "$config_file"
            local removed_count
            removed_count=$(echo "$invalid_paths" | wc -w)
            log_info "Config updated: removed $removed_count invalid path(s)"
            printf "   [OK] Removed paths:%s\n" "$invalid_paths"
        else
            rm -f "$tmp_file"
            log_error "Failed to update config"
            return 1
        fi

        # 提示重启
        log_info "Restart gateway to apply changes: systemctl --user restart openclaw-gateway"

        return 0
    }
}

# --- repair-plugins-sdk.sh ---
# repair-plugins-sdk.sh - Fix plugin SDK compatibility issues
# Handles: ERR_MODULE_NOT_FOUND (plugin-sdk), api.config.get incompatibility,
#          and invalid plugins.load.paths entries

repair_plugins_sdk() {
    describe() {
        echo "Fix plugin SDK module missing or API incompatibility issues"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Detect root cause: module missing vs API incompatibility vs bad paths"
        echo "  - For ERR_MODULE_NOT_FOUND: attempt npm install in the plugin directory"
        echo "  - For api.config.get / API error: disable the offending plugin (rename .js -> .clawicu-disabled)"
        echo "  - For invalid plugins.load.paths: remove non-existent entries from config"
    }

    # Re-parse doctor output to get current details
    _sdk_doctor_out() {
        echo "${CLAWICU_DOCTOR_OUT:-}"
    }

    # Find path of the plugin with SDK import error
    _find_sdk_plugin_path() {
        local doc="$(_sdk_doctor_out)"
        [ -f "$doc" ] || return 1
        grep "imported from\|ERR_MODULE_NOT_FOUND" "$doc" 2>/dev/null | head -1 \
            | grep -o '/[^ ]*\.js' | head -1
    }

    # Find path of the plugin with API incompatibility (at activate ...)
    _find_api_broken_path() {
        local doc="$(_sdk_doctor_out)"
        [ -f "$doc" ] || return 1
        grep "at activate" "$doc" 2>/dev/null | head -1 \
            | grep -o '(/[^)]*)' | tr -d '()' | sed 's/:[0-9]*:[0-9]*$//'
    }

    # Find plugin ID from "WARN id: plugin register returned a promise" line
    _find_api_broken_id() {
        local doc="$(_sdk_doctor_out)"
        [ -f "$doc" ] || return 1
        grep "plugin register returned a promise\|async registration is ignored" "$doc" 2>/dev/null \
            | head -1 | sed 's/.*WARN[[:space:]]*\([a-zA-Z0-9_-]*\):.*/\1/'
    }

    # Remove invalid entries from plugins.load.paths in config
    _fix_invalid_paths() {
        local config_file="$HOME/.openclaw/openclaw.json"
        [ -f "$config_file" ] || return 0
        command -v jq >/dev/null 2>&1 || {
            log_warn "jq not available; cannot auto-fix plugins.load.paths"
            return 1
        }

        local paths
        paths=$(jq -r '.plugins.load.paths[]? // empty' "$config_file" 2>/dev/null)
        [ -n "$paths" ] || return 0

        local removed=0
        local valid_json="[]"
        for path in $paths; do
            expanded="${path/#\~/$HOME}"
            expanded="${expanded/\$HOME/$HOME}"
            if [ -d "$expanded" ]; then
                valid_json=$(printf '%s' "$valid_json" | jq --arg p "$path" '. + [$p]')
            else
                log_warn "Removing invalid path: $path"
                removed=$((removed + 1))
            fi
        done

        [ "$removed" -eq 0 ] && return 0

        local tmp
        tmp=$(mktemp)
        if jq --argjson v "$valid_json" '.plugins.load.paths = $v' "$config_file" > "$tmp"; then
            mv "$tmp" "$config_file"
            printf "   [OK] Removed %d invalid plugin path(s) from config\n" "$removed"
            return 0
        fi
        rm -f "$tmp"
        return 1
    }

    execute() {
        log_info "Starting plugin SDK repair..."

        local doc="${CLAWICU_DOCTOR_OUT:-}"
        local repaired=0

        # --- Case 1: ERR_MODULE_NOT_FOUND for plugin-sdk ---
        if [ -f "$doc" ] && grep -q "Cannot find module.*plugin-sdk\|ERR_MODULE_NOT_FOUND.*plugin-sdk" "$doc" 2>/dev/null; then
            printf "   [*] Detected: plugin-sdk module missing\n"
            local broken_path
            broken_path="$(_find_sdk_plugin_path)"
            if [ -n "$broken_path" ]; then
                local plugin_dir
                plugin_dir="$(dirname "$broken_path")"
                # Walk up to find the directory with package.json
                while [ -n "$plugin_dir" ] && [ "$plugin_dir" != "/" ]; do
                    [ -f "$plugin_dir/package.json" ] && break
                    plugin_dir="$(dirname "$plugin_dir")"
                done
                if [ -f "$plugin_dir/package.json" ]; then
                    printf "   [*] Running npm install in: %s\n" "$plugin_dir"
                    if (cd "$plugin_dir" && npm install --prefer-offline 2>/dev/null); then
                        printf "   [OK] npm install succeeded\n"
                        repaired=$((repaired + 1))
                    else
                        printf "   [!] npm install failed - disabling plugin instead\n"
                        if mv "$broken_path" "${broken_path}.clawicu-disabled" 2>/dev/null; then
                            printf "   [OK] Plugin disabled: %s\n" "$broken_path"
                            repaired=$((repaired + 1))
                        fi
                    fi
                fi
            fi
        fi

        # --- Case 2: api.config.get / API incompatibility ---
        if [ -f "$doc" ] && grep -q "api\.config\.get is not a function\|TypeError:.*is not a function\|ReferenceError:" "$doc" 2>/dev/null; then
            printf "   [*] Detected: plugin API incompatibility (api.config.get)\n"
            local broken_path broken_id
            broken_path="$(_find_api_broken_path)"
            broken_id="$(_find_api_broken_id)"

            if [ -n "$broken_path" ] && [ -f "$broken_path" ]; then
                if mv "$broken_path" "${broken_path}.clawicu-disabled" 2>/dev/null; then
                    printf "   [OK] Plugin disabled: %s\n" "$broken_path"
                    printf "   [i]  Restore: mv \"%s.clawicu-disabled\" \"%s\"\n" "$broken_path" "$broken_path"
                    repaired=$((repaired + 1))
                fi
            fi

            # Also add to plugins.deny if we have an ID
            if [ -n "$broken_id" ] && command -v openclaw >/dev/null 2>&1; then
                openclaw config set "plugins.deny" "[\"${broken_id}\"]" 2>/dev/null && \
                    printf "   [OK] Added '%s' to plugins.deny\n" "$broken_id" || true
            fi
        fi

        # --- Case 3: Invalid plugins.load.paths ---
        if _fix_invalid_paths; then
            repaired=$((repaired + 1))
        fi

        if [ "$repaired" -eq 0 ]; then
            log_warn "Could not automatically repair plugin SDK issues"
            printf "   [!] Manual steps:\n"
            printf "       1. Run: openclaw update\n"
            printf "       2. Or disable the broken plugin manually\n"
            return 1
        fi

        # Verify
        local verify="$CLAWICU_TMPDIR/doctor-verify-sdk.txt"
        openclaw doctor > "$verify" 2>&1 || true
        if ! grep -q "api\.config\.get is not a function\|ERR_MODULE_NOT_FOUND.*plugin-sdk" "$verify" 2>/dev/null; then
            printf "   [OK] Verification passed\n"
        fi

        return 0
    }
}

# --- repair-plugins.sh ---
# repair-plugins.sh - Disable plugins that crash or use deprecated APIs

repair_plugins() {
    describe() {
        echo "Disable OpenClaw plugins with runtime errors or API compatibility issues"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Run 'openclaw doctor' and parse output for plugin errors"
        echo "  - Identify broken plugin IDs and file paths"
        echo "  - Rename broken plugin entry-point to .disabled (non-destructive)"
        echo "  - OR set plugins.allow to exclude broken plugins"
        echo "  - Verify 'openclaw doctor' passes after disabling"
    }

    # Parse doctor output file for the broken plugin's JS file path
    # Returns: absolute path to the plugin's main JS file, or empty string
    _find_broken_plugin_path() {
        local doctor_out="${CLAWICU_DOCTOR_OUT:-}"
        [ -f "$doctor_out" ] || return 1
        # "at activate (/path/to/plugin/dist-node/index.js:LINE:COL)"
        # grep -o '(/[^)]*)' matches the whole "(path:line:col)" group
        grep "at activate" "$doctor_out" 2>/dev/null | head -1 \
            | grep -o '(/[^)]*)' | tr -d '()' | sed 's/:[0-9]*:[0-9]*$//'
    }

    # Parse doctor output file for the broken plugin's ID
    # Returns: plugin ID string (e.g. "workflow-orchestration"), or empty string
    _find_broken_plugin_id() {
        local doctor_out="${CLAWICU_DOCTOR_OUT:-}"
        [ -f "$doctor_out" ] || return 1
        # "│  - WARN workflow-orchestration: plugin register returned a promise"
        # Use sed to extract the identifier after "WARN "
        grep "plugin register returned a promise\|async registration is ignored" "$doctor_out" 2>/dev/null \
            | head -1 | sed 's/.*WARN[[:space:]]*\([a-zA-Z0-9_-]*\):.*/\1/'
    }

    # Get all plugin IDs that are currently loaded (from doctor output)
    _list_all_plugin_ids() {
        local doctor_out="${CLAWICU_DOCTOR_OUT:-}"
        [ -f "$doctor_out" ] || return 1
        # "plugins.allow is empty; discovered non-bundled plugins may auto-load: id1 (...), id2 (...),"
        grep "plugins.allow is empty" "$doctor_out" 2>/dev/null \
            | grep -o '[a-zA-Z0-9_-]*[[:space:]]*(/' \
            | sed 's/[[:space:]]*(\/$//'
    }

    # Disable by renaming the entry-point JS file (non-destructive, reversible)
    _disable_by_rename() {
        local js_path="$1"
        if [ -z "$js_path" ] || [ ! -f "$js_path" ]; then
            return 1
        fi
        local backup="${js_path}.clawicu-disabled"
        if mv "$js_path" "$backup" 2>/dev/null; then
            log_info "Disabled: $js_path -> $backup"
            log_info "To re-enable: mv \"$backup\" \"$js_path\""
            return 0
        fi
        log_warn "Could not rename $js_path"
        return 1
    }

    # Set plugins.allow to exclude the broken plugin ID
    # Requires: openclaw config set plugins.allow '[...]'
    _disable_by_allowlist() {
        local broken_id="$1"
        [ -z "$broken_id" ] && return 1

        # Build allow list from currently discovered plugins, excluding the broken one
        local all_ids
        all_ids="$(_list_all_plugin_ids)"

        local allow_list=""
        for id in $all_ids; do
            if [ "$id" != "$broken_id" ]; then
                if [ -z "$allow_list" ]; then
                    allow_list="\"$id\""
                else
                    allow_list="$allow_list,\"$id\""
                fi
            fi
        done

        if [ -z "$allow_list" ]; then
            log_warn "Could not build plugin allow list - no plugin IDs found in doctor output"
            return 1
        fi

        if command -v openclaw >/dev/null 2>&1; then
            openclaw config set plugins.allow "[$allow_list]" 2>/dev/null && return 0
        fi

        # Manual fallback: edit openclaw.json directly
        local cfg="$HOME/.openclaw/openclaw.json"
        if [ -f "$cfg" ] && command -v node >/dev/null 2>&1; then
            node - "$cfg" "$broken_id" "$allow_list" <<'JSEOF'
const fs = require('fs');
const file = process.argv[2];
const brokenId = process.argv[3];
let raw = fs.readFileSync(file, 'utf8');
// Strip JS-style comments (JSON5)
raw = raw.replace(/\/\/[^\n]*/g, '').replace(/\/\*[\s\S]*?\*\//g, '');
let cfg;
try { cfg = JSON.parse(raw); } catch(e) { cfg = {}; }
if (!cfg.plugins) cfg.plugins = {};
// Build allow list excluding broken plugin
const current = Array.isArray(cfg.plugins.allow) ? cfg.plugins.allow : [];
// If allow was empty (auto-load all), we don't know all IDs - just set deny instead
if (current.length === 0) {
    cfg.plugins.deny = (cfg.plugins.deny || []).filter(x => x !== brokenId).concat([brokenId]);
} else {
    cfg.plugins.allow = current.filter(x => x !== brokenId);
}
fs.writeFileSync(file, JSON.stringify(cfg, null, 2));
console.log('Updated config:', JSON.stringify(cfg.plugins));
JSEOF
            return $?
        fi

        return 1
    }

    # Fix "plugins.allow is empty" by explicitly listing all discovered plugins.
    # This makes future plugin loading deterministic and removes the security risk.
    _fix_allow_empty() {
        local doctor_out="${CLAWICU_DOCTOR_OUT:-}"
        local all_ids
        all_ids="$(_list_all_plugin_ids)"

        if [ -z "$all_ids" ]; then
            # Try reading extension dirs directly as fallback
            local ext_dir="$HOME/.openclaw/extensions"
            if [ -d "$ext_dir" ]; then
                for d in "$ext_dir"/*/; do
                    [ -d "$d" ] || continue
                    local id
                    id="$(basename "$d")"
                    all_ids="${all_ids:+$all_ids }$id"
                done
            fi
        fi

        if [ -z "$all_ids" ]; then
            log_warn "Could not determine installed plugin IDs"
            printf "   [!] Manual fix: openclaw config set plugins.allow '[\"your-plugin-id\"]'\n"
            return 1
        fi

        # Build JSON array
        local allow_json=""
        for id in $all_ids; do
            allow_json="${allow_json:+$allow_json,}\"$id\""
        done
        allow_json="[$allow_json]"

        printf "   [*] Setting plugins.allow to: %s\n" "$allow_json"

        if command -v openclaw >/dev/null 2>&1; then
            if openclaw config set plugins.allow "$allow_json" 2>/dev/null; then
                printf "   [OK] plugins.allow updated - only listed plugins will load\n"
                return 0
            fi
        fi

        # Manual fallback via Node.js
        local cfg="$HOME/.openclaw/openclaw.json"
        if [ -f "$cfg" ] && command -v node >/dev/null 2>&1; then
            node - "$cfg" "$allow_json" <<'JSEOF'
const fs = require('fs');
const [,, file, allow] = process.argv;
let raw = fs.readFileSync(file, 'utf8');
raw = raw.replace(/\/\/[^\n]*/g, '').replace(/\/\*[\s\S]*?\*\//g, '');
let cfg; try { cfg = JSON.parse(raw); } catch(e) { cfg = {}; }
if (!cfg.plugins) cfg.plugins = {};
cfg.plugins.allow = JSON.parse(allow);
fs.writeFileSync(file, JSON.stringify(cfg, null, 2));
console.log('Updated plugins.allow:', allow);
JSEOF
            return $?
        fi

        log_warn "Could not update plugins.allow automatically"
        printf "   [!] Manual fix: openclaw config set plugins.allow '%s'\n" "$allow_json"
        return 1
    }

    execute() {
        log_info "Starting plugin repair..."

        local doctor_out="${CLAWICU_DOCTOR_OUT:-}"

        if [ ! -f "$doctor_out" ]; then
            log_info "No doctor output file found, running openclaw doctor now..."
            CLAWICU_DOCTOR_OUT="$CLAWICU_TMPDIR/doctor-output.txt"
            openclaw doctor > "$CLAWICU_DOCTOR_OUT" 2>&1 || true
            doctor_out="$CLAWICU_DOCTOR_OUT"
            export CLAWICU_DOCTOR_OUT
        fi

        # Case A: plugins.allow is empty (security risk warning)
        if grep -q "plugins.allow is empty" "$doctor_out" 2>/dev/null; then
            log_info "Detected: plugins.allow is empty - will set explicit allow list"
            if _fix_allow_empty; then
                return 0
            fi
            return 1
        fi

        # Case B: runtime crash / API compatibility errors
        if ! grep -q "Unhandled promise rejection\|is not a function\|is not defined\|plugin register returned a promise" \
                "$doctor_out" 2>/dev/null; then
            log_info "No plugin errors detected in doctor output"
            return 0
        fi

        local broken_path
        broken_path="$(_find_broken_plugin_path)"
        local broken_id
        broken_id="$(_find_broken_plugin_id)"

        log_info "Broken plugin path: ${broken_path:-not detected}"
        log_info "Broken plugin ID:   ${broken_id:-not detected}"

        local repaired=0

        # Strategy 1: Disable by renaming the entry-point JS (most reliable)
        if [ -n "$broken_path" ]; then
            printf "   [*] Disabling broken plugin: %s\n" "$broken_path"
            if _disable_by_rename "$broken_path"; then
                repaired=1
                printf "   [OK] Plugin disabled (entry-point renamed to .clawicu-disabled)\n"
                printf "   [i]  To re-enable: mv \"%s.clawicu-disabled\" \"%s\"\n" "$broken_path" "$broken_path"
            fi
        fi

        # Strategy 2: Also update plugins config to add to deny list (belt & suspenders)
        if [ -n "$broken_id" ]; then
            printf "   [*] Adding '%s' to plugins.deny in config...\n" "$broken_id"
            if _disable_by_allowlist "$broken_id"; then
                repaired=1
                printf "   [OK] Config updated: plugin '%s' is now excluded\n" "$broken_id"
            else
                log_warn "Could not update plugins config automatically"
                printf "   [!] Manual fix: run: openclaw config set plugins.deny '[\"${broken_id}\"]'\n"
            fi
        fi

        if [ "$repaired" -eq 0 ]; then
            log_warn "Could not automatically disable the broken plugin"
            printf "   [!] Manual steps:\n"
            [ -n "$broken_path" ] && printf "       mv \"%s\" \"%s.disabled\"\n" "$broken_path" "$broken_path"
            [ -n "$broken_id" ]   && printf "       openclaw config set plugins.deny '[\"${broken_id}\"]'\n"
            return 1
        fi

        # Verify fix
        printf "   [*] Verifying repair (running openclaw doctor)...\n"
        local verify_out="$CLAWICU_TMPDIR/doctor-verify.txt"
        openclaw doctor > "$verify_out" 2>&1 || true
        if grep -q "Unhandled promise rejection\|is not a function" "$verify_out" 2>/dev/null; then
            log_warn "Plugin errors still present after repair"
            return 1
        else
            printf "   [OK] Verification passed - no more plugin runtime errors\n"
        fi

        return 0
    }
}

# --- repair-port.sh ---
# repair-port.sh - Free port 18789 or reconfigure gateway port


# Source dependencies

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
            # POSIX-safe: grep -oP is GNU-only; use grep -o + cut instead
            result=$(ss -tlnp 2>/dev/null | grep ":${port}[[:space:]]" \
                | grep -o 'pid=[0-9]*' | head -1 | cut -d= -f2 || true)
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

        printf "   Kill this process? [y/N]: "
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

# --- repair-reinstall.sh ---
# repair-reinstall.sh - Complete clean reinstall of OpenClaw (HIGH RISK)


# Source dependencies

repair_reinstall() {
    describe() {
        echo "Complete clean reinstall of OpenClaw (MOST DESTRUCTIVE)"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - *** WARNING: THIS IS THE MOST DESTRUCTIVE REPAIR ***"
        echo "  - Create full backup of ALL OpenClaw data"
        echo "  - Stop any running OpenClaw processes"
        echo "  - Uninstall OpenClaw completely (npm/Docker)"
        echo "  - Remove ~/.openclaw/ entirely"
        echo "  - Perform a clean fresh install"
        echo "  - Nothing is preserved - start from scratch"
        echo "  - Backup is kept for manual recovery"
    }

    # Print extensive warning and require double confirmation
    _warn_and_confirm() {
        echo "" >&2
        log_warn "=============================================="
        log_warn "  *** MOST DESTRUCTIVE OPERATION ***"
        log_warn "=============================================="
        log_warn ""
        log_warn "This will COMPLETELY REMOVE OpenClaw:"
        log_warn "  - ALL data will be destroyed"
        log_warn "  - ALL sessions, plugins, config GONE"
        log_warn "  - ALL credentials will be destroyed"
        log_warn "  - The application itself will be uninstalled"
        log_warn "  - Then reinstalled fresh from scratch"
        log_warn ""
        log_warn "A backup will be made, but this is the"
        log_warn "LAST RESORT. Try other repairs first."
        log_warn ""
        log_warn "=============================================="
        printf "Type 'FULL-REINSTALL' to proceed: " >&2

        read -r confirmation1
        if [ "$confirmation1" != "FULL-REINSTALL" ]; then
            log_info "Reinstall cancelled by user"
            return 1
        fi

        printf "Are you ABSOLUTELY sure? Type 'YES' to confirm: " >&2
        read -r confirmation2
        if [ "$confirmation2" != "YES" ]; then
            log_info "Reinstall cancelled by user"
            return 1
        fi

        return 0
    }

    # Stop any running OpenClaw processes
    _stop_processes() {
        log_info "Stopping OpenClaw processes..."

        # Try graceful stop first
        if command -v openclaw >/dev/null 2>&1; then
            openclaw stop 2>/dev/null || true
        fi

        # Kill any remaining processes
        local pids
        pids=$(pgrep -f "openclaw" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            log_warn "Killing remaining OpenClaw processes: $pids"
            echo "$pids" | xargs kill 2>/dev/null || true
            sleep 2
            echo "$pids" | xargs kill -9 2>/dev/null || true
        fi
    }

    # Uninstall OpenClaw based on install method
    _uninstall() {
        local install_method="$1"

        case "$install_method" in
            npm-global)
                log_info "Uninstalling via npm (global)..."
                npm uninstall -g openclaw 2>&1 || true
                ;;
            npm-local)
                log_info "Uninstalling via npm (local)..."
                npm uninstall openclaw 2>&1 || true
                ;;
            docker)
                log_info "Removing Docker container..."
                docker rm -f openclaw 2>/dev/null || true
                ;;
            podman)
                log_info "Removing Podman container..."
                podman rm -f openclaw 2>/dev/null || true
                ;;
            *)
                log_warn "Unknown install method: $install_method"
                log_info "Attempting npm uninstall as fallback..."
                npm uninstall -g openclaw 2>&1 || true
                ;;
        esac
    }

    # Clean install OpenClaw
    _clean_install() {
        local install_method="$1"

        case "$install_method" in
            npm-global|npm-local|unknown)
                log_info "Installing OpenClaw fresh via npm..."
                npm install -g openclaw 2>&1
                return $?
                ;;
            docker)
                log_info "Creating fresh Docker container..."
                docker run -d --name openclaw openclaw:latest 2>&1
                return $?
                ;;
            podman)
                log_info "Creating fresh Podman container..."
                podman run -d --name openclaw openclaw:latest 2>&1
                return $?
                ;;
            *)
                log_info "Attempting npm install..."
                npm install -g openclaw 2>&1
                return $?
                ;;
        esac
    }

    # Verify installation works
    _verify_install() {
        if command -v openclaw >/dev/null 2>&1; then
            local version
            version=$(openclaw --version 2>/dev/null || echo "unknown")
            log_info "OpenClaw installed: version $version"
            return 0
        fi

        # Check Docker
        if docker ps 2>/dev/null | grep -q openclaw; then
            log_info "OpenClaw container is running"
            return 0
        fi

        return 1
    }

    execute() {
        log_info "Starting REINSTALL repair..."
        log_warn "This is the MOST DESTRUCTIVE repair option"

        # Require double confirmation
        if ! _warn_and_confirm; then
            return 1
        fi

        local install_method="$CLAWICU_INSTALL_METHOD"
        local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

        # Create full backup before anything
        log_info "Creating full backup of all data..."
        local backup_path
        backup_path="$(backup_create "repair-reinstall")"
        log_info "Full backup created: $backup_path"
        log_info "This backup will be preserved even after reinstall"

        state_push "repair-reinstall"

        # Stop processes
        _stop_processes

        # Uninstall
        log_info "Uninstalling current OpenClaw..."
        _uninstall "$install_method"

        # Remove all state data
        if [ -d "$state_dir" ]; then
            log_warn "Removing state directory: $state_dir"
            rm -rf "$state_dir"
        fi

        # Clean install
        log_info "Performing clean install..."
        if ! _clean_install "$install_method"; then
            log_fatal "Clean install failed. Backup is at: $backup_path"
            return 1
        fi

        # Verify
        if _verify_install; then
            log_info "Reinstall completed successfully"
            log_info "Backup of previous installation: $backup_path"
            log_warn "You need to set up OpenClaw from scratch (credentials, config, plugins)"
            return 0
        else
            log_fatal "Verification failed after reinstall"
            log_info "Backup is available at: $backup_path"
            return 1
        fi
    }
}

# --- repair-sessions.sh ---
# repair-sessions.sh - Remove corrupted session files by moving them aside


# Source dependencies

repair_sessions() {
    describe() {
        echo "Detect and quarantine corrupted session files"
    }

    dry_run() {
        echo "What would happen:"
        echo "  - Scan session directory for all session files"
        echo "  - Parse each file to detect JSON corruption"
        echo "  - Move corrupted sessions to ~/.openclaw/sessions/corrupted/"
        echo "  - Sessions are NOT deleted - just moved aside for safety"
        echo "  - Report summary of moved sessions"
    }

    # Get the sessions directory
    _sessions_dir() {
        echo "${OPENCLAW_SESSIONS_DIR:-$HOME/.openclaw/sessions}"
    }

    # Validate a session file is valid JSON
    # Args: $1 = file path
    _is_valid_session() {
        local session_file="$1"

        if [ ! -f "$session_file" ]; then
            return 1
        fi

        # Empty file is corrupted
        local size
        size=$(wc -c < "$session_file" 2>/dev/null || echo 0)
        if [ "$size" -eq 0 ]; then
            return 1
        fi

        # Try node first for strict JSON validation
        if command -v node >/dev/null 2>&1; then
            node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8'))" "$session_file" 2>/dev/null
            return $?
        fi

        # Fall back to python
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$session_file" 2>/dev/null
            return $?
        fi

        # Last resort: basic structure check
        if grep -q '{' "$session_file" 2>/dev/null && grep -q '}' "$session_file" 2>/dev/null; then
            return 0
        fi
        return 1
    }

    # List all session files
    # Args: $1 = sessions directory
    _list_session_files() {
        local sdir="$1"
        if [ ! -d "$sdir" ]; then
            return 1
        fi

        # Match common session file patterns
        for f in "$sdir"/*.json "$sdir"/*/*.json; do
            if [ -f "$f" ]; then
                echo "$f"
            fi
        done
    }

    execute() {
        log_info "Starting sessions repair..."

        local sdir
        sdir=$(_sessions_dir)

        if [ ! -d "$sdir" ]; then
            log_warn "No sessions directory found at: $sdir"
            log_info "Nothing to repair"
            return 0
        fi

        # Create corrupted sessions quarantine directory
        local corrupted_dir="$sdir/corrupted"
        mkdir -p "$corrupted_dir"

        backup_create "repair-sessions"
        state_push "repair-sessions"

        local total_count=0
        local corrupted_count=0
        local moved_list=""

        # Check each session file
        for session_file in $(_list_session_files "$sdir"); do
            # Skip files already in the corrupted directory
            case "$session_file" in
                */corrupted/*) continue ;;
            esac

            total_count=$((total_count + 1))

            if _is_valid_session "$session_file"; then
                log_debug "Session $(basename "$session_file"): OK"
            else
                corrupted_count=$((corrupted_count + 1))
                local fname
                fname=$(basename "$session_file")
                local dest="$corrupted_dir/$fname"

                # Avoid overwriting existing files in corrupted dir
                if [ -f "$dest" ]; then
                    local timestamp
                    timestamp=$(date '+%Y%m%d-%H%M%S')
                    dest="$corrupted_dir/${fname}.$timestamp"
                fi

                mv "$session_file" "$dest"
                log_info "Moved corrupted session: $fname -> corrupted/$fname"
                moved_list="$moved_list $fname"
            fi
        done

        if [ "$total_count" -eq 0 ]; then
            log_info "No session files found"
            return 0
        fi

        log_info "Scanned $total_count session(s), found $corrupted_count corrupted"
        if [ "$corrupted_count" -gt 0 ]; then
            log_info "Corrupted sessions moved to: $corrupted_dir"
            log_info "Moved:$moved_list"
        fi

        log_info "Sessions repair completed"
        return 0
    }
}

# --- repair-version-mismatch.sh ---
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
            openclaw daemon stop >/dev/null 2>&1 || true
            sleep 1
            if openclaw daemon start >/dev/null 2>&1; then
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

# === BUNDLED DISPATCH LISTS ===
_CLAWICU_CHECK_FNS="binary channel_policy config_schema config credentials daemon disk docker envvars exec_approvals gateway install_method node plugins_sdk plugins port sessions state_dir version_mismatch version"
_CLAWICU_REPAIR_FNS="channel_policy config_field config credentials daemon docker downgrade gateway nuclear plugins_paths plugins_sdk plugins port reinstall sessions version_mismatch"

# === MAIN ORCHESTRATOR ===

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAWICU_VERSION="0.2.0"


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

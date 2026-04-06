#!/bin/sh
# repair-credentials.sh - Detect and prompt for missing provider credentials

set -e

# Source dependencies
. "$(dirname "$0")/../lib/bootstrap.sh"
. "$(dirname "$0")/../lib/backup.sh"
. "$(dirname "$0")/../lib/state.sh"
. "$(dirname "$0")/../lib/log.sh"

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
        # shell — a pipe would create a subshell and variable updates
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

        log_info "Credentials repair completed"
        return 0
    }
}

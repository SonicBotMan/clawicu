#!/bin/sh
# repair-docker.sh - Restart and recreate Docker container and volumes

set -e

# Source dependencies
. "$(dirname "$0")/../lib/bootstrap.sh"
. "$(dirname "$0")/../lib/backup.sh"
. "$(dirname "$0")/../lib/state.sh"
. "$(dirname "$0")/../lib/log.sh"

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
        # is passed as a distinct word — avoids word-splitting on paths with spaces.
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

#!/usr/bin/env bash
# Home Assistant add-on entrypoint for MercurySandbox.
#
# The image is the MercurySandbox controller. This script turns the add-on
# options into the .env that controller expects, brings the gateway up as a
# sibling container on the host's Docker (the add-on has docker_api), joins
# the sandbox network so the web page can reach the gateway, and runs
# mercuryd behind ingress. Nothing here duplicates the stack: `mercury up`
# and `mercury serve` are the same commands used on a laptop or a server.
set -euo pipefail

OPTIONS_FILE=/data/options.json
ENV_FILE=/data/mercury.env
GENERATED_KEY_FILE=/data/master-key
CONFIG_DIR=/config
DOCKER_SOCK=/run/docker.sock
INGRESS_PROXY=172.30.32.2
PORT=5004

export MERCURY_ROOT=/opt/mercury
export MERCURY_ENV_FILE="$ENV_FILE"
GATEWAY_CONFIG="$MERCURY_ROOT/gateway/config.yaml"
GATEWAY_CONFIG_DEFAULT="$MERCURY_ROOT/gateway/config.default.yaml"

log() {
    echo "[mercury] $*"
}

# Print the value of an option, or an empty string if it is absent or null.
opt() {
    jq -r --arg k "$1" \
        'if (has($k) and .[$k] != null) then (.[$k] | tostring) else "" end' \
        "$OPTIONS_FILE"
}

if [ ! -f "$OPTIONS_FILE" ]; then
    log "WARNING: $OPTIONS_FILE not found, falling back to defaults"
    OPTIONS_FILE=/tmp/mercury-options.json
    echo '{}' > "$OPTIONS_FILE"
fi

# --- Docker -------------------------------------------------------------------

# The Supervisor mounts the host socket at /run/docker.sock when docker_api is
# set. Point the CLI at it explicitly rather than relying on /var/run.
if [ -S "$DOCKER_SOCK" ]; then
    export DOCKER_HOST="unix://$DOCKER_SOCK"
fi
if ! docker info > /dev/null 2>&1; then
    log "FATAL: cannot reach the host's Docker at ${DOCKER_HOST:-the default socket}."
    log "This add-on needs docker_api, which the Supervisor grants from config.yaml."
    log "If the add-on was installed from a different repository, that grant is missing."
    exit 1
fi

# --- Options to .env ----------------------------------------------------------

MASTER_KEY=$(opt litellm_master_key)
if [ -z "$MASTER_KEY" ]; then
    # Generate once and keep it in add-on storage, so clients configured with
    # it keep working across restarts and updates. It is printed to the log
    # so it can be copied into Hermes or opencode-manager.
    if [ ! -s "$GENERATED_KEY_FILE" ]; then
        (umask 077; echo "sk-$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')" > "$GENERATED_KEY_FILE")
        log "No litellm_master_key set, generated one and kept it in add-on storage"
    fi
    MASTER_KEY=$(cat "$GENERATED_KEY_FILE")
    log "Gateway master key (from add-on storage): ${MASTER_KEY}"
fi

ANTHROPIC_API_KEY=$(opt anthropic_api_key)
OPENROUTER_API_KEY=$(opt openrouter_api_key)
OPENAI_API_KEY=$(opt openai_api_key)
if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENROUTER_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
    log "WARNING: no provider key set (anthropic_api_key, openrouter_api_key, openai_api_key)."
    log "WARNING: the gateway will start but every model call will fail."
fi

GIT_TOKEN=$(opt git_token)
[ -n "$GIT_TOKEN" ] || log "WARNING: git_token is empty, sandboxes can clone public repos but never push"

GIT_NAME=$(opt git_name)
[ -n "$GIT_NAME" ] || GIT_NAME=mercury-sandbox
GIT_EMAIL=$(opt git_email)
[ -n "$GIT_EMAIL" ] || GIT_EMAIL=agents@example.com
DEFAULT_MODEL=$(opt default_model)
[ -n "$DEFAULT_MODEL" ] || DEFAULT_MODEL=cheap-default
# The add-on version is the MercurySandbox release it wraps, so the matching
# sandbox image is the default and a version bump carries both.
addon_version() {
    curl -sS -m 10 -H "Authorization: Bearer ${SUPERVISOR_TOKEN:-}" \
        http://supervisor/addons/self/info 2>/dev/null | jq -r '.data.version // empty' || true
}
SANDBOX_IMAGE=$(opt sandbox_image)
if [ -z "$SANDBOX_IMAGE" ]; then
    SANDBOX_IMAGE="ghcr.io/benkelly/mercury-sandbox:$(addon_version)"
    case "$SANDBOX_IMAGE" in
        *:) SANDBOX_IMAGE="${SANDBOX_IMAGE}latest"
            log "WARNING: could not read the add-on version, using the latest sandbox image" ;;
    esac
fi
SANDBOX_MEMORY=$(opt sandbox_memory)
[ -n "$SANDBOX_MEMORY" ] || SANDBOX_MEMORY=2g
SANDBOX_CPUS=$(opt sandbox_cpus)
[ -n "$SANDBOX_CPUS" ] || SANDBOX_CPUS=2
EXPOSE_GATEWAY=$(opt expose_gateway)
API_TOKEN=$(opt api_token)
TUNNEL_TOKEN=$(opt cloudflare_tunnel_token)

GATEWAY_BIND=127.0.0.1
if [ "$EXPOSE_GATEWAY" = "true" ]; then
    GATEWAY_BIND=0.0.0.0
    log "expose_gateway is on: the gateway listens on every host interface, port 4000"
fi

# Write KEY="value" lines that both bash and docker compose read the same way.
# Keys and tokens never contain these characters; refuse rather than guess.
env_line() {
    case "$2" in
        *['"$\\']* | *$'\n'*)
            log "FATAL: option $3 contains a quote, backslash, dollar sign or newline"
            exit 1
            ;;
    esac
    printf '%s="%s"\n' "$1" "$2"
}

(
    umask 077
    {
        env_line LITELLM_MASTER_KEY "$MASTER_KEY" litellm_master_key
        env_line ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY" anthropic_api_key
        env_line OPENROUTER_API_KEY "$OPENROUTER_API_KEY" openrouter_api_key
        env_line OPENAI_API_KEY "$OPENAI_API_KEY" openai_api_key
        env_line SANDBOX_GIT_TOKEN "$GIT_TOKEN" git_token
        env_line SANDBOX_GIT_NAME "$GIT_NAME" git_name
        env_line SANDBOX_GIT_EMAIL "$GIT_EMAIL" git_email
        env_line SANDBOX_DEFAULT_MODEL "$DEFAULT_MODEL" default_model
        env_line SANDBOX_IMAGE "$SANDBOX_IMAGE" sandbox_image
        env_line SANDBOX_MEMORY "$SANDBOX_MEMORY" sandbox_memory
        env_line SANDBOX_CPUS "$SANDBOX_CPUS" sandbox_cpus
        env_line GATEWAY_BIND "$GATEWAY_BIND" expose_gateway
        env_line MERCURY_API_TOKEN "$API_TOKEN" api_token
        env_line CLOUDFLARE_TUNNEL_TOKEN "$TUNNEL_TOKEN" cloudflare_tunnel_token
    } > "$ENV_FILE"
)

# --- Model routing ------------------------------------------------------------

# Keep the shipped config.yaml pristine on first start after install or
# update, so switching back from a custom file restores the default.
[ -f "$GATEWAY_CONFIG_DEFAULT" ] || cp "$GATEWAY_CONFIG" "$GATEWAY_CONFIG_DEFAULT"
mkdir -p "$CONFIG_DIR"
cp "$GATEWAY_CONFIG_DEFAULT" "$CONFIG_DIR/litellm.example.yaml"
if [ -f "$CONFIG_DIR/litellm.yaml" ]; then
    cp "$CONFIG_DIR/litellm.yaml" "$GATEWAY_CONFIG"
    log "Model routing from ${CONFIG_DIR}/litellm.yaml"
else
    cp "$GATEWAY_CONFIG_DEFAULT" "$GATEWAY_CONFIG"
    log "Model routing from the built-in config (copy ${CONFIG_DIR}/litellm.example.yaml to litellm.yaml to change it)"
fi

# --- Stack --------------------------------------------------------------------

# This container is the controller, so only the gateway (and the tunnel, when
# there is a token) run as compose services.
MERCURY_SERVICES=gateway
[ -n "$TUNNEL_TOKEN" ] && MERCURY_SERVICES="gateway cloudflared"
export MERCURY_SERVICES

log "Bringing the gateway up on the host's Docker (first start pulls images, be patient)"
mercury up

# Find this container so it can be attached to agentnet. The Supervisor names
# add-on containers addon_<slug>, and /addons/self/info reports that slug
# with its repository prefix.
self_container() {
    local slug
    slug=$(curl -sS -m 10 -H "Authorization: Bearer ${SUPERVISOR_TOKEN:-}" \
        http://supervisor/addons/self/info 2>/dev/null | jq -r '.data.slug // empty' || true)
    if [ -n "$slug" ] && docker inspect "addon_${slug}" > /dev/null 2>&1; then
        echo "addon_${slug}"
        return 0
    fi
    # Fallback: the labels the add-on builder stamps on the image.
    docker ps -q --filter label=io.hass.type=addon --filter label=io.hass.name=MercurySandbox | head -n1
}

SELF=$(self_container)
if [ -z "$SELF" ]; then
    log "WARNING: could not identify this container, the web page cannot reach the gateway"
elif docker inspect "$SELF" --format '{{json .NetworkSettings.Networks}}' | jq -e 'has("agentnet")' > /dev/null; then
    log "Already attached to agentnet as ${SELF}"
else
    docker network connect --alias mercury agentnet "$SELF"
    log "Attached ${SELF} to agentnet"
fi

# --- mercuryd behind ingress --------------------------------------------------

shutdown() {
    log "Stopping"
    if [ -n "${MERCURYD_PID:-}" ]; then
        kill "$MERCURYD_PID" 2> /dev/null || true
    fi
    mercury stop > /dev/null 2>&1 || log "WARNING: could not stop the gateway"
    running=$(docker ps --filter label=mercury.sandbox --format '{{.Names}}' 2> /dev/null || true)
    if [ -n "$running" ]; then
        log "WARNING: sandboxes still running without a gateway, they will fail:"
        echo "$running" | sed 's/^/[mercury]   /'
    fi
    exit 0
}
trap shutdown TERM INT

log "Sandbox image: ${SANDBOX_IMAGE}, default model: ${DEFAULT_MODEL}, caps: ${SANDBOX_MEMORY} / ${SANDBOX_CPUS} cpus"
log "Starting mercuryd on port ${PORT} for ingress"
MERCURY_BIND=0.0.0.0 \
MERCURY_PORT="$PORT" \
MERCURY_INGRESS_ONLY=1 \
MERCURY_TRUSTED_PROXY="$INGRESS_PROXY" \
MERCURY_GATEWAY_URL=http://gateway:4000/v1 \
    mercury serve &
MERCURYD_PID=$!
wait "$MERCURYD_PID"

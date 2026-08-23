#!/bin/sh
# Home Assistant add-on entrypoint for AIOStreams.
#
# Reads the add-on options from /data/options.json, exports them as the
# environment variables AIOStreams expects, forces all persistent state into
# /data, then hands over to the upstream entrypoint.
#
# The upstream image is Google Distroless: /bin/sh is a minimal busybox with
# almost no applets (no cat, no env, no mkdir). Only shell builtins and jq are
# used below.
set -eu

OPTIONS_FILE=/data/options.json
DEFAULT_PORT=3000

log() {
    echo "[aiostreams] $*"
}

# Print the value of an option, or an empty string if it is absent or null.
opt() {
    jq -r --arg k "$1" \
        'if (has($k) and .[$k] != null) then (.[$k] | tostring) else "" end' \
        "$OPTIONS_FILE"
}

# Export an option as an environment variable, skipping it when empty.
export_opt() {
    _value=$(opt "$2")
    if [ -n "$_value" ]; then
        export "$1=$_value"
    fi
}

if [ ! -f "$OPTIONS_FILE" ]; then
    log "WARNING: $OPTIONS_FILE not found, falling back to an empty configuration"
    OPTIONS_FILE=/tmp/aiostreams-options.json
    echo '{}' > "$OPTIONS_FILE"
fi

# --- Required ---------------------------------------------------------------

# Returns the configured key, or generates and stores one when it is blank.
SECRET_KEY=$(/nodejs/bin/node /ensure-secret-key.js)
if [ -z "$SECRET_KEY" ]; then
    log "FATAL: SECRET_KEY is not set and one could not be generated."
    log "Generate one with: openssl rand -hex 32"
    log "Then set it in the add-on Configuration tab and restart."
    exit 1
fi
case "$SECRET_KEY" in
    *[!0-9a-fA-F]* | "")
        log "FATAL: SECRET_KEY must be a 64 character hex string."
        exit 1
        ;;
esac
if [ "${#SECRET_KEY}" -ne 64 ]; then
    log "FATAL: SECRET_KEY must be 64 characters long, got ${#SECRET_KEY}."
    exit 1
fi
export SECRET_KEY

# BASE_URL is mandatory upstream, so fall back to the usual Home Assistant
# hostname when the user has not supplied one.
BASE_URL=$(opt BASE_URL)
if [ -z "$BASE_URL" ]; then
    BASE_URL="http://homeassistant.local:${DEFAULT_PORT}"
    log "BASE_URL not set, falling back to ${BASE_URL}."
    log "Set it explicitly if you reach Home Assistant on a different address."
fi
export BASE_URL

# --- Persistent state -------------------------------------------------------

# /data is the only directory that survives an add-on update, so the database
# and the disk caches are pinned there. A user supplied DATABASE_URI (for
# example a PostgreSQL server) takes precedence.
DATABASE_URI=$(opt DATABASE_URI)
if [ -z "$DATABASE_URI" ]; then
    DATABASE_URI="sqlite:///data/db.sqlite"
fi
export DATABASE_URI
export DISK_CACHE_DIR=/data/cache

# --- Optional ---------------------------------------------------------------

export_opt ADDON_NAME ADDON_NAME
export_opt AIOSTREAMS_AUTH AIOSTREAMS_AUTH
export_opt AIOSTREAMS_AUTH_PERMISSIONS AIOSTREAMS_AUTH_PERMISSIONS
export_opt REDIS_URI REDIS_URI
export_opt LOG_LEVEL LOG_LEVEL
export_opt LOG_FORMAT LOG_FORMAT
export_opt SYSTEM_LIFECYCLE_ENABLED SYSTEM_LIFECYCLE_ENABLED

# The web port is fixed and mapped by the add-on configuration.
export PORT="$DEFAULT_PORT"

log "Starting AIOStreams on port ${PORT} with base URL ${BASE_URL}"

# Upstream Entrypoint + Cmd, exactly as reported by docker inspect.
exec /nodejs/bin/node /app/packages/server/dist/server.js

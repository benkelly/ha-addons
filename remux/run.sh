#!/bin/sh
# Home Assistant add-on entrypoint for Remux.
#
# Reads the add-on options from /data/options.json and exports them as the
# environment variables Remux reads, then hands over to the upstream binary.
#
# Persistence needs no help here. The upstream image already points DATA_DIR,
# DATABASE_URL, TORRENT_DATA_DIR and LOG_FILE at /data, which is exactly the
# directory the Supervisor keeps across add-on updates.
set -eu

OPTIONS_FILE=/data/options.json
SERVER=/app/remux-server

log() {
    echo "[remux] $*"
}

# Print the value of an option, or an empty string if it is absent or null.
opt() {
    jq -r --arg k "$1" \
        'if (has($k) and .[$k] != null) then (.[$k] | tostring) else "" end' \
        "$OPTIONS_FILE"
}

if [ ! -f "$OPTIONS_FILE" ]; then
    log "WARNING: $OPTIONS_FILE not found, falling back to defaults"
    OPTIONS_FILE=/tmp/remux-options.json
    echo '{}' > "$OPTIONS_FILE"
fi

LOG_LEVEL=$(opt log_level)
[ -n "$LOG_LEVEL" ] || LOG_LEVEL=info

DISABLE_DHT=$(opt disable_dht)
[ -n "$DISABLE_DHT" ] || DISABLE_DHT=false

# Remux logs through tracing's EnvFilter, whose default is "warn,remux=info".
# Keep the dependency crates quiet and only move the Remux level.
export RUST_LOG="warn,remux=${LOG_LEVEL}"
export DISABLE_DHT

if [ "$DISABLE_DHT" = "true" ]; then
    log "DHT gossip disabled"
fi

log "Log level: ${LOG_LEVEL}"
log "Data directory: ${DATA_DIR:-/data}"
log "Starting Remux on port 3000"

exec "$SERVER"

#!/bin/sh
# Home Assistant add-on entrypoint for UHF Server.
#
# Reads the add-on options from /data/options.json, builds the uhf-server
# command line from them, and execs the binary. The database is pinned to
# /data so it survives add-on updates, and recordings default to the Home
# Assistant media folder so they show up in the media browser.
set -eu

OPTIONS_FILE=/data/options.json
DB_PATH=/data/db.json

log() {
    echo "[uhf-server] $*"
}

# Print the value of an option, or an empty string if it is absent or null.
opt() {
    jq -r --arg k "$1" \
        'if (has($k) and .[$k] != null) then (.[$k] | tostring) else "" end' \
        "$OPTIONS_FILE"
}

if [ ! -f "$OPTIONS_FILE" ]; then
    log "WARNING: $OPTIONS_FILE not found, falling back to defaults"
    OPTIONS_FILE=/tmp/uhf-server-options.json
    echo '{}' > "$OPTIONS_FILE"
fi

PORT=$(opt port)
[ -n "$PORT" ] || PORT=8000

RECORDINGS_DIR=$(opt recordings_dir)
[ -n "$RECORDINGS_DIR" ] || RECORDINGS_DIR=/media/uhf-recordings

PASSWORD=$(opt password)
ENABLE_COMMERCIAL_DETECTION=$(opt enable_commercial_detection)

if [ ! -d "$RECORDINGS_DIR" ]; then
    log "Creating recordings directory ${RECORDINGS_DIR}"
    mkdir -p "$RECORDINGS_DIR"
fi

# The Supervisor always provides /data, but the server cannot create the
# database file itself if the directory is missing.
mkdir -p "$(dirname "$DB_PATH")"

# Build the argument list in the positional parameters, which is the POSIX way
# of handling an array in sh.
set -- --host 0.0.0.0 \
    --port "$PORT" \
    --recordings-dir "$RECORDINGS_DIR" \
    --db-path "$DB_PATH"

if [ -n "$PASSWORD" ]; then
    set -- "$@" --password "$PASSWORD"
    log "Password protection enabled"
else
    log "No password set, the server is unprotected on your network"
fi

if [ "$ENABLE_COMMERCIAL_DETECTION" = "true" ]; then
    set -- "$@" --enable-commercial-detection
    log "Commercial detection enabled"
fi

log "Recordings directory: ${RECORDINGS_DIR}"
log "Database: ${DB_PATH}"
log "Starting UHF Server on port ${PORT}"

exec uhf-server "$@"

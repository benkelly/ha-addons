#!/bin/sh
# Home Assistant add-on entrypoint for Tvheadend.
#
# Reads the add-on options from /data/options.json, builds the tvheadend
# command line from them, and execs the binary.
#
# Upstream keeps its configuration in /var/lib/tvheadend, which is inside the
# container and would be lost on every add-on update, so -c points it at /data
# instead.
set -eu

OPTIONS_FILE=/data/options.json
CONFIG_DIR=/data/config
RECORDINGS_DIR=/media/tvheadend-recordings
HTTP_PORT=9981
HTSP_PORT=9982

log() {
    echo "[tvheadend] $*"
}

# Print the value of an option, or an empty string if it is absent or null.
opt() {
    jq -r --arg k "$1" \
        'if (has($k) and .[$k] != null) then (.[$k] | tostring) else "" end' \
        "$OPTIONS_FILE"
}

if [ ! -f "$OPTIONS_FILE" ]; then
    log "WARNING: $OPTIONS_FILE not found, falling back to defaults"
    OPTIONS_FILE=/tmp/tvheadend-options.json
    echo '{}' > "$OPTIONS_FILE"
fi

ADAPTERS=$(opt adapters)
FIRST_RUN_NO_AUTH=$(opt first_run_no_auth)
DEBUG=$(opt debug)

mkdir -p "$CONFIG_DIR"

# Recordings live in the Home Assistant media folder so they show up in the
# media browser. Tvheadend itself is pointed at this path from the DVR profile
# in the web interface, which is why it is only created here.
if [ ! -d "$RECORDINGS_DIR" ]; then
    log "Creating recordings directory ${RECORDINGS_DIR}"
    mkdir -p "$RECORDINGS_DIR"
fi

# Build the argument list in the positional parameters, which is the POSIX way
# of handling an array in sh.
set -- -c "$CONFIG_DIR" \
    --http_port "$HTTP_PORT" \
    --htsp_port "$HTSP_PORT"

if [ -n "$ADAPTERS" ]; then
    set -- "$@" -a "$ADAPTERS"
    log "Restricting to adapters: ${ADAPTERS}"
fi

if [ "$FIRST_RUN_NO_AUTH" = "true" ]; then
    # -C only takes effect while no user account exists, but it does grant
    # unauthenticated administrative access until one is created.
    set -- "$@" -C
    log "WARNING: first_run_no_auth is on, administration is unauthenticated"
    log "WARNING: create an admin user, then turn it off and restart"
fi

if [ "$DEBUG" = "true" ]; then
    set -- "$@" -d
    log "Debug logging enabled"
fi

if [ -d /dev/dvb ]; then
    log "DVB adapters present: $(ls /dev/dvb 2>/dev/null | tr '\n' ' ')"
else
    log "No /dev/dvb, continuing with network sources only (IPTV, SAT>IP)"
fi

log "Configuration: ${CONFIG_DIR}"
log "Starting Tvheadend on port ${HTTP_PORT}, HTSP on ${HTSP_PORT}"

exec tvheadend "$@"

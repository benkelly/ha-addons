#!/bin/sh
# Home Assistant add-on entrypoint for Dispatcharr.
#
# Translates the add-on options into the environment the upstream all-in-one
# image expects, then hands back to the upstream entrypoint so its s6 init
# brings up Postgres, Redis, Celery, uWSGI and nginx exactly as it would
# outside Home Assistant.
#
# Persistence needs almost no help: the all-in-one image already keeps
# everything under /data, which is the directory the Supervisor preserves
# across add-on updates. The one exception is recordings, see below.
set -eu

OPTIONS_FILE=/data/options.json
UPSTREAM_ENTRYPOINT=/app/docker/entrypoint.sh
RECORDINGS_LINK=/data/recordings
RECORDINGS_TARGET=/media/dispatcharr-recordings

log() {
    echo "[dispatcharr] $*"
}

# Print the value of an option, or an empty string if it is absent or null.
opt() {
    jq -r --arg k "$1" \
        'if (has($k) and .[$k] != null) then (.[$k] | tostring) else "" end' \
        "$OPTIONS_FILE"
}

if [ ! -f "$OPTIONS_FILE" ]; then
    log "WARNING: $OPTIONS_FILE not found, falling back to defaults"
    OPTIONS_FILE=/tmp/dispatcharr-options.json
    echo '{}' > "$OPTIONS_FILE"
fi

LOG_LEVEL=$(opt log_level)
[ -n "$LOG_LEVEL" ] || LOG_LEVEL=info

PUID=$(opt puid)
[ -n "$PUID" ] || PUID=1000

PGID=$(opt pgid)
[ -n "$PGID" ] || PGID=1000

TRUSTED_PROXIES=$(opt trusted_proxies)
SETUP_ALLOWED_IP=$(opt setup_allowed_ip)

# Postgres refuses to run as root and the upstream init rejects PUID or PGID of
# zero outright, so catch it here with a message that names the option.
if [ "$PUID" = "0" ] || [ "$PGID" = "0" ]; then
    log "FATAL: puid and pgid cannot be 0."
    log "Dispatcharr runs PostgreSQL, which refuses to run as root."
    log "Set them to a non-zero value, 1000 is the default."
    exit 1
fi

# Dispatcharr hardcodes its DVR root to /data/recordings, with no setting to
# move it, so point that at the Home Assistant media folder with a symlink.
# Recordings then appear in the media browser and survive uninstalling the
# add-on, which anything under /data would not.
if [ -L "$RECORDINGS_LINK" ]; then
    :
elif [ -d "$RECORDINGS_LINK" ]; then
    # A real directory means an earlier version already recorded here. Leave it
    # alone rather than risk stranding those files.
    log "WARNING: ${RECORDINGS_LINK} is a real directory, leaving it as it is"
    log "WARNING: recordings stay in add-on storage and are lost if you uninstall"
else
    mkdir -p "$RECORDINGS_TARGET"
    ln -s "$RECORDINGS_TARGET" "$RECORDINGS_LINK"
    log "Recordings directed to ${RECORDINGS_TARGET}"
fi

# All-in-one mode: Postgres and Redis run inside this container.
export DISPATCHARR_ENV=aio
export REDIS_HOST=localhost
export CELERY_BROKER_URL=redis://localhost:6379/0
export DISPATCHARR_LOG_LEVEL="$LOG_LEVEL"
export PUID
export PGID

if [ -n "$TRUSTED_PROXIES" ]; then
    export DISPATCHARR_TRUSTED_PROXIES="$TRUSTED_PROXIES"
    log "Trusted proxies: ${TRUSTED_PROXIES}"
fi

if [ -n "$SETUP_ALLOWED_IP" ]; then
    export DISPATCHARR_SETUP_ALLOWED_IP="$SETUP_ALLOWED_IP"
    log "First run setup additionally allowed from ${SETUP_ALLOWED_IP}"
fi

log "Log level: ${LOG_LEVEL}"
log "Running services as ${PUID}:${PGID}"
log "Starting Dispatcharr on port 9191, this takes a minute on first run"

exec "$UPSTREAM_ENTRYPOINT"

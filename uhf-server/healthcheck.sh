#!/bin/sh
# Docker HEALTHCHECK for UHF Server, which the Supervisor watches to restart
# the add-on when the server stops responding. This replaces the add-on
# 'watchdog' option, which is obsolete.
#
# The port is configurable, so it is read back from the add-on options the same
# way run.sh builds the command line from them.
set -eu

PORT=8000
if [ -f /data/options.json ]; then
    configured=$(jq -r '.port // empty' /data/options.json)
    if [ -n "$configured" ]; then
        PORT=$configured
    fi
fi

# This is a liveness check, so any HTTP response means the server is up.
# Without --fail curl exits 0 whatever the status, and only reports an error
# when it cannot get a response at all. The status is deliberately not checked:
# /server/stats answers 401 once a password is set, and a protected server is
# still a healthy one.
if ! curl -s -o /dev/null --max-time 5 --noproxy '*' \
        "http://127.0.0.1:${PORT}/server/stats"; then
    echo "[uhf-server] no response from port ${PORT}"
    exit 1
fi

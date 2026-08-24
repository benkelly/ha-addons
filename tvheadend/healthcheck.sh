#!/bin/sh
# Docker HEALTHCHECK for Tvheadend, which the Supervisor watches to restart the
# add-on when the server stops responding.
set -eu

PORT=9981

# This is a liveness check, so any HTTP response means the server is up.
# Without --fail curl exits 0 whatever the status, and only reports an error
# when it cannot get a response at all. The status is deliberately not checked:
# Tvheadend answers 401 once authentication is configured, and a protected
# server is still a healthy one.
if ! curl -s -o /dev/null --max-time 5 --noproxy '*' \
        "http://127.0.0.1:${PORT}/"; then
    echo "[tvheadend] no response from port ${PORT}"
    exit 1
fi

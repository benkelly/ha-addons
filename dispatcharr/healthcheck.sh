#!/bin/sh
# Docker HEALTHCHECK for Dispatcharr, which the Supervisor watches to restart
# the add-on when the web front end stops responding.
set -eu

PORT=9191

# This is a liveness check, so any HTTP response means nginx and uWSGI are up.
# Without --fail curl exits 0 whatever the status, and only reports an error
# when it cannot get a response at all. The status is deliberately not checked:
# Dispatcharr redirects or returns 401 depending on login state, and both mean
# a healthy server.
if ! curl -s -o /dev/null --max-time 5 --noproxy '*' \
        "http://127.0.0.1:${PORT}/"; then
    echo "[dispatcharr] no response from port ${PORT}"
    exit 1
fi

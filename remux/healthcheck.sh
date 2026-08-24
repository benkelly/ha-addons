#!/bin/sh
# Docker HEALTHCHECK for Remux, which the Supervisor watches to restart the
# add-on when the server stops responding.
#
# The listening port is fixed at 3000 and mapped by the add-on configuration,
# so unlike the UHF Server check there is nothing to read back from the options.
set -eu

PORT=3000

# This is a liveness check, so any HTTP response means the server is up.
# Without --fail curl exits 0 whatever the status, and only reports an error
# when it cannot get a response at all.
if ! curl -s -o /dev/null --max-time 5 --noproxy '*' \
        "http://127.0.0.1:${PORT}/health"; then
    echo "[remux] no response from port ${PORT}"
    exit 1
fi

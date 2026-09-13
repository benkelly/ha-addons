#!/bin/sh
# Docker HEALTHCHECK for the MercurySandbox add-on, which the Supervisor
# watches to restart the add-on when mercuryd stops responding.
set -eu

PORT=5004

# /api/health is the one endpoint mercuryd never authenticates, so this works
# from loopback even though everything else is ingress-only.
if ! curl -fsS -o /dev/null --max-time 5 --noproxy '*' \
        "http://127.0.0.1:${PORT}/api/health"; then
    echo "[mercury] no response from port ${PORT}"
    exit 1
fi

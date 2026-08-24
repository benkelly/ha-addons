# Tvheadend publishes no version tags, only rolling ones (edge, latest,
# master, master-debian), so there is no release tag to pin. The image is
# pinned by digest instead, which is reproducible in the same way.
#
# This is master-debian as of 2026-08-22, tvheadend 4.3-2763~g45cbe4adb.
# Pinning the index digest rather than a per-platform one keeps it multi-arch.
FROM ghcr.io/tvheadend/tvheadend@sha256:2a1ecd9690070686b4d301d79cfe10f22936c38e68981b169f87162257d1cf8c

# Upstream runs as the unprivileged tvheadend user, which cannot write the root
# owned /data the Supervisor provides. Add-ons run as root by convention, so
# switch back and let run.sh own the data directory.
USER root

# The upstream image is Debian 13 and carries neither jq nor curl. jq reads the
# add-on options and curl drives the health check below.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq curl \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /run.sh /healthcheck.sh

# The Supervisor restarts the add-on when this reports unhealthy. Tvheadend
# scans adapters at start, so allow a generous grace period.
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD /healthcheck.sh

# Keep tini from the upstream entrypoint so ffmpeg and streaming child
# processes are reaped. Upstream's /init is only an argv shim, so run.sh takes
# its place and execs tvheadend itself.
ENTRYPOINT ["/usr/bin/tini", "--", "/run.sh"]
CMD []

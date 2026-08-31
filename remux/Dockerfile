FROM ghcr.io/lostb1t/remux:0.28.0

# The upstream image is Debian 13 and already ships jellyfin-ffmpeg7, yt-dlp and
# curl, so jq is the only thing that needs adding to read the add-on options.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /run.sh /healthcheck.sh

# The Supervisor restarts the add-on when this reports unhealthy. Remux runs
# database migrations and a library scan at start, so allow a long grace period.
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD /healthcheck.sh

# Upstream sets no entrypoint and defaults to CMD ["./remux-server"], relative
# to its /app working directory. run.sh sets the environment from the add-on
# options and then execs that binary.
ENTRYPOINT ["/run.sh"]
CMD []

FROM docker.io/swapplications/uhf-server:2.0.0

# The upstream image is Ubuntu 25.04 and already ships FFmpeg 7.1.1 (upstream
# requires 7 or newer) and comskip for commercial detection. jq reads the
# add-on options and curl drives the health check below.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq curl \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /run.sh /healthcheck.sh

# The Supervisor restarts the add-on when this reports unhealthy, which is what
# the obsolete 'watchdog' add-on option used to do. Recordings start slowly on
# small hardware, so allow a generous start period.
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

# Upstream sets no entrypoint and defaults to CMD ["bash"], expecting the
# uhf-server command line to be supplied by the caller. run.sh builds that
# command line from the add-on options.
ENTRYPOINT ["/run.sh"]
CMD []

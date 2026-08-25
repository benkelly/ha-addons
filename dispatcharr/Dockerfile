FROM ghcr.io/dispatcharr/dispatcharr:0.29.0

# The upstream image is a LinuxServer style s6-overlay build and already
# carries curl, so jq is the only thing needed to read the add-on options.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /run.sh /healthcheck.sh

# Postgres, Redis, Celery, uWSGI and nginx all start behind this, so the first
# run takes a while. Allow a long grace period before the check counts.
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD /healthcheck.sh

# run.sh only translates the add-on options into the environment upstream
# expects, then hands straight back to the upstream entrypoint so s6 comes up
# exactly as it does outside Home Assistant.
ENTRYPOINT ["/run.sh"]
CMD []

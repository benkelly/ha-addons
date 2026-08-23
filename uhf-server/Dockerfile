FROM docker.io/swapplications/uhf-server:2.0.0

# The upstream image is Ubuntu 25.04 and already ships FFmpeg 7.1.1 (upstream
# requires 7 or newer) and comskip for commercial detection, so jq is the only
# thing that needs adding.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

# Upstream sets no entrypoint and defaults to CMD ["bash"], expecting the
# uhf-server command line to be supplied by the caller. run.sh builds that
# command line from the add-on options.
ENTRYPOINT ["/run.sh"]
CMD []

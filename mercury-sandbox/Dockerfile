FROM ghcr.io/benkelly/mercury:0.1.0

# The upstream image is the MercurySandbox controller: Alpine with bash,
# docker-cli, compose, git, jq, curl and python3 already in place, so nothing
# needs installing. run.sh only turns the add-on options into the .env the
# controller expects and then runs the same `mercury up` and `mercury serve`
# a person would run on a server.
COPY run.sh /run.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /run.sh /healthcheck.sh

# The first start pulls a LiteLLM image and the sandbox image before mercuryd
# comes up, which can take a few minutes on a slow link. Allow for it before
# the check counts.
HEALTHCHECK --interval=30s --timeout=10s --start-period=600s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/run.sh"]
CMD []

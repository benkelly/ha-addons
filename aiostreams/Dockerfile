# jq is not present in the upstream image and the base is Google Distroless,
# which ships no package manager. Take a static, multi-arch jq from the
# official jq image instead of installing one.
FROM ghcr.io/jqlang/jq:1.8.1 AS jq

FROM ghcr.io/viren070/aiostreams:v2.34.0

COPY --from=jq /jq /usr/local/bin/jq
COPY ensure-secret-key.js /ensure-secret-key.js
COPY run.sh /run.sh

# The upstream base has no chmod, so run.sh is invoked through the shell
# rather than relying on an execute bit.
ENTRYPOINT ["/bin/sh", "/run.sh"]
CMD []

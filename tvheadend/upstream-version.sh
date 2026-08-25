#!/bin/sh
# Prints the add-on version for a given Tvheadend image reference, used by the
# digest update workflow. Run with IMAGE_REF set, for example:
#
#   IMAGE_REF=ghcr.io/tvheadend/tvheadend@sha256:... ./upstream-version.sh
#
# Tvheadend has no releases to version against, so this uses what the binary
# reports: "4.3-2763~g45cbe4adb" becomes "4.3.2763". The middle number is the
# commit count since the 4.3 tag, so it always moves forward, which is what
# Home Assistant needs to offer an update.
set -eu

raw="$(docker run --rm --entrypoint tvheadend "${IMAGE_REF:?IMAGE_REF is required}" --version)"

version="$(echo "$raw" \
    | sed -n 's/.*version \([0-9][0-9.]*\)-\([0-9][0-9]*\)~.*/\1.\2/p' \
    | head -n1)"

if [ -z "$version" ]; then
    echo "Could not parse a version from: ${raw}" >&2
    exit 1
fi

echo "$version"

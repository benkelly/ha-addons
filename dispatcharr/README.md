# Dispatcharr

Home Assistant add-on wrapping the official
[Dispatcharr](https://github.com/Dispatcharr/Dispatcharr) all-in-one image
(`ghcr.io/dispatcharr/dispatcharr`).

Dispatcharr consolidates multiple IPTV providers into one tidy source. It
merges M3U playlists, matches XMLTV or Schedules Direct guide data to channels,
records, and re-serves everything as M3U, XMLTV, Xtream Codes or an emulated
HDHomeRun. Licensed AGPL-3.0.

Supported architectures: `amd64`, `aarch64`.

See [DOCS.md](./DOCS.md) for setup and the full option reference.

## Quick start

1. Install the add-on and start it. First start takes a couple of minutes while
   PostgreSQL initialises.
2. Click **Open Web UI** and create the admin account.
3. Add your M3U playlists and EPG sources, then tidy up channels and guide
   matching.
4. Point Tvheadend, Jellyfin or Plex at the HDHomeRun output, or use the M3U
   and XMLTV URLs directly.

## Where this fits

Tvheadend and Remux can both take an M3U directly. Dispatcharr is worth running
in front of them when you have several providers with duplicate channels,
inconsistent naming or guide data that does not line up. With a single tidy
provider it is extra moving parts for little gain.

## Note on size

The image is around 4.2 GB and runs PostgreSQL, Redis, Celery, uWSGI and nginx
inside the one container. It is by far the heaviest add-on in this repository.

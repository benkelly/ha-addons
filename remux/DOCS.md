# Remux

Thin wrapper around the official `ghcr.io/lostb1t/remux` image, pinned to an
exact upstream tag.

## Before you install

The image is around 2.1 GB. It bundles `jellyfin-ffmpeg7`, `yt-dlp` and, on
`amd64`, the Intel compute runtime for tone mapping. That is a lot to pull onto
a host running from an SD card.

Remux is also pre-1.0 and moves quickly, so expect breaking changes between
releases and read the upstream notes on each bump.

## Architecture support

Upstream publishes both `linux/amd64` and `linux/arm64`, confirmed against the
image manifest, so both `amd64` and `aarch64` are listed in `config.yaml`.

## Setup

1. Add this repository to Home Assistant, then install **Remux**.
2. Start the add-on. The defaults work, so nothing needs configuring first.
3. Click **Open Web UI**, or browse to port `3000`, and use the Remux dashboard
   to add sources and users.
4. Point any Jellyfin client at the same address, for example
   `http://homeassistant.local:3000`.

Almost everything is configured from the Remux dashboard rather than through
Home Assistant. The two add-on options below cover only the settings that have
to be in place before the server starts.

## Options

### `log_level`

One of `error`, `warn`, `info`, `debug`, `trace`. Defaults to `info`.

This sets the level for Remux itself and leaves its dependencies at `warn`, so
raising it does not drown the log in noise from libraries.

### `disable_dht`

Turns off the DHT gossip socket. Defaults to `false`.

Worth enabling if you have no torrent sources configured, or if your network
blocks the traffic and you would rather not have the server trying.

## Data and persistence

Everything lives in `/data`, which survives add-on restarts and updates. The
upstream image already points its data paths there, so the add-on does not have
to override anything:

- `/data/db.sqlite`, the library, users and playback state
- `/data/cache`, cached metadata and images
- `/data/torrents`, torrent working data
- `/data/transcode_sessions`, in-flight transcodes
- `/data/logs/remux.jsonl`, the structured log, which grows over time

Uninstalling the add-on removes `/data`, so back up `/data/db.sqlite` first if
you want to keep your libraries and users.

## Media access

The Home Assistant media folder is mapped read and write at `/media`, so
anything under it can be added to a Remux library as a local file source.

Nothing else on the host is exposed. Remux still reaches Stremio add-ons,
WebDAV servers and torrents over the network without any extra access.

## Hardware transcoding

Not enabled. The add-on does not pass through `/dev/dri`, so transcoding is
done in software. That is fine for direct play and light remuxing, and slow for
anything that needs a real transcode.

If you want hardware acceleration, the add-on needs a `devices` entry for your
GPU. Raise it and it can be added, bearing in mind it lowers the add-on
security rating.

## Networking

- **3000** serves both the web interface and the Jellyfin compatible API.
  Change the host side of the mapping in the **Network** section if `3000` is
  taken.
- **6881** is the torrent peer port, announced to trackers so they return you
  in peer lists. Outbound only streaming works without it being reachable, so
  leave it alone unless you are forwarding the port at your router.

The container health check polls `/health` every 30 seconds, after a 120 second
grace period at start, since Remux runs migrations and a library scan on first
boot. If the server stops responding the Supervisor restarts the add-on.

## RemuxDB

Remux submits stream probe results to the public
[RemuxDB](https://remuxdb.1632022.xyz) instance so clients see consistent audio
and subtitle track data. It is on by default and is a dashboard setting rather
than an add-on option, so turn it off in the Remux settings if you would rather
not send anything.

## Updates

Updates are manual tag bumps. The Dockerfile pins an exact upstream tag, so a
rebuild always produces the same version.

A scheduled workflow checks for new upstream releases daily and opens a pull
request bumping the pinned tag, the add-on version and the changelog. Each bump
is reviewed and merged by hand.

Note that upstream git tags carry a `v` prefix but the published image tags do
not, so `v0.26.0` in the release list is `0.26.0` on the registry. The update
workflow handles the difference.

## Troubleshooting

**The add-on takes a long time to start.** First boot runs database migrations
and an initial scan. The health check allows two minutes before it starts
checking.

**Jellyfin clients cannot connect.** Use the Home Assistant host address and
the mapped port, not `localhost`. Remux does not advertise itself over the
network from a bridged add-on.

**Playback stutters on transcodes.** There is no hardware acceleration, see
above. Prefer clients that can direct play your sources.

**The log is filling `/data`.** Lower `log_level`, and clear
`/data/logs/remux.jsonl` if it has grown large.

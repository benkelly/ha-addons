# Dispatcharr

Thin wrapper around the official `ghcr.io/dispatcharr/dispatcharr` all-in-one
image, pinned to an exact upstream tag.

## Before you install

The image is around 4.2 GB and runs PostgreSQL, Redis, Celery, uWSGI and nginx
inside a single container. It is the heaviest add-on in this repository by a
wide margin, and first start takes a couple of minutes while the database
initialises. Check your disk and memory before putting it on a small host.

Dispatcharr is also pre-1.0, at `0.29.0`, so expect breaking changes between
versions and read the upstream release notes on each bump.

## Setup

1. Add this repository to Home Assistant, then install **Dispatcharr**.
2. Start the add-on and wait. The health check allows three minutes before it
   starts counting failures.
3. Click **Open Web UI**, or browse to port `9191`, and create the admin
   account.
4. Add your M3U playlists under **Playlists**, and your XMLTV or Schedules
   Direct sources under **EPG**, then match channels to guide data.

Everything else is configured from the Dispatcharr interface. The options below
only cover what has to be set before the container starts.

## Options

### `log_level`

One of `trace`, `debug`, `info`, `warning`, `error`, `critical`. Defaults to
`info`. Anything below `info` is very noisy given how many services run inside.

### `puid` and `pgid`

The user and group the services run as. Both default to `1000`.

**Neither can be `0`.** Dispatcharr runs PostgreSQL, which refuses to run as
root, and upstream rejects a zero value outright. The add-on checks this first
and fails with a clear message rather than letting the container die inside the
upstream init.

Change these only if you need recordings written to `/media` to be owned by a
specific user, for example to match a share you mount elsewhere.

### `trusted_proxies`

Sets which peers may set `X-Real-IP` and `X-Forwarded-For`. Leave blank for the
usual case, where private and loopback peers are trusted. Set an IP or CIDR to
narrow that, or `none` to ignore proxy headers entirely. Worth setting if you
put Dispatcharr behind a reverse proxy.

### `setup_allowed_ip`

Allows first-time superuser creation from one extra public IP. Leave blank
unless you are setting the instance up from outside your own network, and clear
it once you have an admin account.

## Data and persistence

Everything lives in `/data`, which survives add-on restarts and updates. The
all-in-one image already puts it there, so the add-on does not override any of
it:

- `/data/db`, the PostgreSQL cluster holding channels, playlists, guide data
  and users
- `/data/m3us`, `/data/epgs`, `/data/uploads`, the source files
- `/data/logos`, `/data/cache`, cached artwork and guide data
- `/data/backups`, `/data/plugins`, `/data/scripts`

Uninstalling the add-on removes `/data`, so take a backup from the Dispatcharr
interface first if you want to keep your setup.

## Recordings

Dispatcharr hardcodes its DVR root to `/data/recordings` and has no setting to
move it. The add-on symlinks that to `/media/dispatcharr-recordings`, so
recordings land in the Home Assistant media folder, show up in the media
browser, and are not lost if you uninstall the add-on.

If an earlier version already recorded into a real `/data/recordings`
directory, the add-on leaves it alone rather than risk stranding those files,
and says so in the log. Move them into `/media/dispatcharr-recordings` by hand
and delete the directory to pick up the symlink.

## Networking

Port `9191` serves the web interface and every output format: M3U, XMLTV,
Xtream Codes and the HDHomeRun emulation. Change the host side of the mapping
in the **Network** section if `9191` is taken.

The container health check polls port `9191` every 30 seconds, after a 180
second grace period. It is a liveness check, so a redirect to the login page or
a `401` still counts as healthy.

## Hardware transcoding

Not enabled. The add-on does not pass through `/dev/dri`, so Dispatcharr's
FFmpeg profiles transcode in software. Stream copy and direct play are
unaffected.

If you want hardware acceleration, the add-on needs a `devices` entry for your
GPU. Raise it and it can be added, bearing in mind it lowers the add-on
security rating.

That is only worth doing if the host has a real GPU to hand over. Home
Assistant running in a virtual machine usually sees a paravirtual display
adapter such as a Virtio GPU, which provides a framebuffer but no video encode
or decode engine, so VAAPI has nothing to bind to no matter what the add-on
requests. On Apple Silicon hosts there is no VAAPI path to pass through at all.
In either case the fix is at the hypervisor level, not here.

## Updates

Updates are manual tag bumps. The Dockerfile pins an exact upstream tag, so a
rebuild always produces the same version.

A scheduled workflow checks for new upstream releases daily and opens a pull
request bumping the pinned tag, the add-on version and the changelog. Each bump
is reviewed and merged by hand.

Note that upstream git tags carry a `v` prefix but the published image tags do
not, so `v0.29.0` in the release list is `0.29.0` on the registry. The update
workflow already handles that, the same as it does for Remux.

## Troubleshooting

**The add-on takes ages to start.** First run initialises a PostgreSQL cluster
and runs Django migrations. Two to three minutes is normal.

**The add-on will not start and the log mentions PUID.** `puid` or `pgid` is
set to `0`. PostgreSQL cannot run as root. Set both back to `1000`.

**Recordings are missing from the media browser.** Check the log for the
warning about `/data/recordings` being a real directory. If it is there, move
the files and remove the directory so the symlink can be created.

**Guide data is thin or wrong.** Dispatcharr matches guide data, it does not
improve it. The quality comes from the source: Schedules Direct is the best
option for UK and Ireland, with XMLTV grabbers as the free alternative.

**The log warns about GPU devices being inaccessible.** Expected, and harmless.
Upstream runs a hardware acceleration check at every start, and it reports
lines such as:

```
⚠️ Device /dev/dri/renderD128 exists but is not accessible.
⚠️ User dispatch cannot access /dev/dri/card0 (permission denied)
⚠️ FFmpeg VAAPI acceleration: NOT DETECTED
```

The device nodes are visible because the Supervisor exposes part of `/dev` to
add-ons, but this add-on does not request them, so opening them is denied. That
is the deliberate choice described under hardware transcoding above. Dispatcharr
starts normally and everything except hardware transcoding works.

The check also prints the GPU it found. If that is a Virtio or other
paravirtual adapter, see hardware transcoding above: passing the devices
through would not help, because there is no video engine behind them. Look for
`⏳ Dispatcharr is running` further down the log to confirm the add-on came up.

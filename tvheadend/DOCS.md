# Tvheadend

Thin wrapper around the official `ghcr.io/tvheadend/tvheadend` image.

## How this add-on is pinned

Unlike the other add-ons here, Tvheadend is **pinned by image digest** rather
than by release tag. That is not a shortcut: the project has no releases to
pin to. Its container repository publishes only five rolling tags (`edge`,
`edge-debian`, `latest`, `master`, `master-debian`), the newest git tags are
`v4.2.8` and `v4.3` with no matching images, and development happens on master.

Pinning the digest gives the same reproducibility a release tag would: a
rebuild always produces the identical image.

The add-on version comes from the binary. Tvheadend reports something like
`4.3-2763~g45cbe4adb`, which becomes `4.3.2763`. The middle number counts
commits since the 4.3 tag, so it always moves forward and Home Assistant can
tell a newer build from an older one.

## Architecture support

Upstream publishes `linux/amd64`, `linux/arm64`, `linux/arm/v7`, `linux/arm/v6`
and `linux/386`. This add-on lists `amd64`, `aarch64` and `armv7`. Only `amd64`
has been tested here; the other two come from the upstream manifest.

## Setup

1. Add this repository to Home Assistant, then install **Tvheadend**.
2. Start the add-on and click **Open Web UI**, or browse to port `9981`.
3. Work through the setup wizard: pick a language, add your tuners and
   networks, scan for muxes and map services to channels.
4. In **Configuration** > **Recording**, set the recording path to
   `/media/tvheadend-recordings` so recordings appear in the Home Assistant
   media browser.

Almost everything is configured from the Tvheadend web interface. The options
below only cover what has to be set before the server starts.

## Options

### `adapters`

Restricts Tvheadend to specific DVB adapters, as a comma separated list of
adapter numbers, for example `0,1`. Leave blank to use every adapter it finds.

Use `-1` to disable DVB adapters entirely if you only have network sources.

### `first_run_no_auth`

Lets Tvheadend create an account with no username and no password when none
exists yet. Defaults to `false`.

This is an escape hatch for a fresh install where you cannot get past the login
screen. It grants **unauthenticated administrative access** to anyone who can
reach the add-on until you create a user, so turn it on, create your admin
account, then turn it off and restart. The add-on logs a warning on every start
while it is enabled.

### `debug`

Enables debug logging to the add-on log. Defaults to `false`. Useful when
diagnosing tuner or scanning problems, noisy otherwise.

## Tuner hardware

DVB tuners are passed through from the host at `/dev/dvb`, and `udev` is
enabled so adapters plugged in after the add-on starts are still picked up. The
add-on logs which adapters it can see at start.

If your tuner is not detected:

- Check the host actually sees it. `ls /dev/dvb` on the Home Assistant host
  should list `adapter0` and so on.
- Some tuners need firmware the host does not ship by default.
- USB tuners on a hub sometimes need a powered hub to enumerate reliably.

Network sources need none of this. IPTV, SAT>IP and HDHomeRun style tuners work
over the network without device access.

## Data and persistence

- `/data/config` holds the whole Tvheadend configuration tree: channels,
  networks, muxes, DVR entries, users and access control.
- `/media/tvheadend-recordings` is created for recordings, though Tvheadend
  only writes there once you set the path in the DVR profile.

Upstream keeps configuration in `/var/lib/tvheadend`, which is inside the
container and would be wiped on every add-on update. The add-on passes
`-c /data/config` instead.

Uninstalling the add-on removes `/data`, so back up `/data/config` first if you
want to keep your channel setup.

## Running as root

The upstream image runs as the unprivileged `tvheadend` user, which cannot
write the root owned `/data` that the Supervisor provides. This add-on runs as
root instead, which is the normal arrangement for Home Assistant add-ons and
also keeps tuner device access simple.

## Networking

- **9981** serves the web interface and HTTP streaming.
- **9982** is HTSP, the native protocol used by Kodi and other Tvheadend
  clients.

Change the host side of either mapping in the **Network** section if those
ports are taken.

The container health check polls port `9981` every 30 seconds, after a 90
second grace period. It is a liveness check, so an authenticated server
answering `401` still counts as healthy.

## Updates

A scheduled workflow checks daily whether the `master-debian` image digest has
moved and, if it has, opens a pull request bumping the pinned digest, the
version and the changelog. Each bump is reviewed and merged by hand.

Because upstream ships from master, a bump can carry anything from a small fix
to a behaviour change, and there are no release notes to read. The pull request
links the upstream commit so you can compare before merging.

## Troubleshooting

**No adapters found.** See the tuner section above. The add-on log lists what
it saw under `/dev/dvb` at start.

**Locked out of the web interface.** Turn on `first_run_no_auth`, restart,
create an admin user, then turn it off and restart again.

**Recordings do not show in the media browser.** The DVR profile path must be
`/media/tvheadend-recordings`, or another path under `/media`. Home Assistant
only indexes the media folder.

**Configuration disappeared after an update.** It should not: it lives in
`/data/config`. Check you have not changed the config path in the web
interface to somewhere inside the container.

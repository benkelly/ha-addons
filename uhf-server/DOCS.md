# UHF Server

Thin wrapper around the official `swapplications/uhf-server` image, pinned to
an exact upstream tag.

## Architecture support

Upstream publishes both `linux/amd64` and `linux/arm64`, confirmed against the
image manifest and by checking that the `uhf-server` and `ffmpeg` binaries in
the arm64 image are genuine aarch64 builds. Both `amd64` and `aarch64` are
therefore listed in `config.yaml`.

## Setup

1. Add this repository to Home Assistant, then install **UHF Server**.
2. Open the **Configuration** tab and set a `password`. The server accepts
   unauthenticated requests otherwise, which is worth avoiding on a shared
   network.
3. Start the add-on.
4. In the UHF app, add the server manually using the Home Assistant host
   address and the mapped port, for example `192.168.1.10:8000`.

### Discovery

UHF Server advertises itself over mDNS. Add-ons run on Docker's bridge
network, so those multicast announcements do not reach the rest of your LAN
and the UHF app will not find the server automatically. Add it by IP address
and port instead.

## Options

### `port`

Port the server listens on inside the container. Defaults to `8000`.

Leave this at `8000` unless you have a specific reason to change it. To reach
the add-on on a different port from the rest of your network, change the host
side of the mapping in the **Network** section of the add-on page instead. The
container side of that mapping is fixed at `8000`, so changing this option
without matching it there will make the add-on unreachable.

### `password`

Password required by the UHF app to talk to the server. Optional, but the
server is unauthenticated when it is left blank, and the add-on logs a warning
saying so.

### `recordings_dir`

Where recordings are written. Defaults to `/media/uhf-recordings`.

`/media` is the Home Assistant media folder, mapped read and write, so
recordings show up in the media browser. The directory is created at start if
it does not exist. Keep the path under `/media` unless you have mapped
something else.

### `enable_commercial_detection`

Runs comskip over finished recordings to mark commercial breaks. Defaults to
`false`. comskip ships in the upstream image, so nothing extra is needed, but
detection is CPU heavy and will be slow on a low powered host.

## Data and persistence

- `/data/db.json` holds the server database, which is where scheduled and
  completed recordings live. `/data` survives add-on restarts and updates.
- `/media/uhf-recordings` holds the recordings themselves. That is the Home
  Assistant media folder, not add-on storage, so recordings are not lost if
  the add-on is uninstalled.

Upstream defaults the database to `/var/lib/uhf-server/db.json`, which is
inside the container and would be wiped on every update. The add-on passes
`--db-path /data/db.json` instead, so nothing is written to the container
filesystem.

Uninstalling the add-on removes `/data`, so back up `/data/db.json` first if
you want to keep your scheduled recordings.

## Networking and health checks

The API is exposed on port `8000`. Change the host side of the mapping in the
**Network** section if `8000` is taken.

The container health check polls `/server/stats` every 30 seconds, after a 60
second grace period at start. If the server stops responding the Supervisor
restarts the add-on. It is a liveness check, so a password protected server
answering `401` still counts as healthy.

## Updates

Updates are manual tag bumps. The Dockerfile pins an exact upstream tag, so a
rebuild always produces the same version.

A scheduled workflow checks for new upstream releases daily and opens a pull
request bumping the pinned tag, the add-on version and the changelog. Each bump
is reviewed and merged by hand.

## Troubleshooting

**The UHF app cannot find the server.** Auto discovery does not work from a
bridged add-on. Add the server by IP address and port.

**Recordings are missing from the media browser.** Check `recordings_dir` is
under `/media`. Home Assistant only indexes the media folder.

**The add-on keeps restarting.** The health check restarts it when
`/server/stats` stops answering. Check the log for the underlying error.

**Commercial detection never finishes.** comskip is CPU bound and roughly real
time on modest hardware. Turn `enable_commercial_detection` off if the host
cannot keep up.

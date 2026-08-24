# Tvheadend

Home Assistant add-on wrapping the official
[Tvheadend](https://github.com/tvheadend/tvheadend) image
(`ghcr.io/tvheadend/tvheadend`).

Tvheadend is a TV streaming server and recorder for DVB-C/C2, DVB-S/S2,
DVB-T/T2, ATSC, IPTV, SAT>IP and unix pipe sources. Licensed GPL-3.0.

Supported architectures: `amd64`, `aarch64`, `armv7`.

See [DOCS.md](./DOCS.md) for setup and the full option reference.

## Quick start

1. Install the add-on and start it.
2. Click **Open Web UI** and work through the setup wizard to add tuners,
   networks and an admin user.
3. Set the DVR recording path to `/media/tvheadend-recordings` so recordings
   appear in the Home Assistant media browser.

If you cannot get past the login screen on a fresh install, turn on
`first_run_no_auth`, create an admin user, then turn it off again.

## Tuner hardware

DVB tuners on the host are passed through at `/dev/dvb`. Network sources such
as IPTV and SAT>IP need no device access at all.

## Pinning

Tvheadend publishes no release tags, only rolling ones, so this add-on pins the
image **by digest** rather than by tag. The version number comes from the
Tvheadend binary itself, for example `4.3.2763`.

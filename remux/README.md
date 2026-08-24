# Remux

Home Assistant add-on wrapping the official
[Remux](https://github.com/lostb1t/remux) image (`ghcr.io/lostb1t/remux`).

Remux is a Jellyfin compatible media server that brings Stremio add-ons, local
files, WebDAV sources and torrents together under one roof. Any Jellyfin client
works against it without changes. Written in Rust, licensed AGPL-3.0.

Supported architectures: `amd64`, `aarch64`.

See [DOCS.md](./DOCS.md) for setup and the full option reference.

## Quick start

1. Install the add-on and start it. The defaults are sensible, so there is
   nothing to configure first.
2. Click **Open Web UI** and work through the Remux dashboard to add sources
   and users.
3. Point your Jellyfin client at the same address, for example
   `http://homeassistant.local:3000`.

Local files under the Home Assistant media folder are available to Remux at
`/media`.

## Note on size

The upstream image is around 2.1 GB, because it bundles `jellyfin-ffmpeg7`,
`yt-dlp` and, on `amd64`, the Intel compute runtime. Check you have the disk
space before installing on a small host.

## Branding assets

`icon.png` and `logo.png` are downscaled from the upstream Remux logo.

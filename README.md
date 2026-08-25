# benkelly's Home Assistant Add-ons

A small Home Assistant add-on repository.

## Add this repository

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fbenkelly%2Fha-addons)

Or add it by hand: **Settings** > **Add-ons** > **Add-on Store** > menu (top right) >
**Repositories**, then paste:

```
https://github.com/benkelly/ha-addons
```

## Add-ons

| Add-on | Description | Architectures |
| ------ | ----------- | ------------- |
| [AIOStreams](./aiostreams) | Consolidates multiple Stremio addons and debrid services into a single, customisable super-addon. | `amd64`, `aarch64` |
| [Dispatcharr](./dispatcharr) | IPTV playlist and EPG management, consolidating multiple providers into one tidy source. | `amd64`, `aarch64` |
| [Remux](./remux) | Jellyfin compatible media server bringing Stremio add-ons, local files and WebDAV sources together. | `amd64`, `aarch64` |
| [Tvheadend](./tvheadend) | TV streaming server and recorder for DVB, ATSC, IPTV and SAT>IP sources. | `amd64`, `aarch64`, `armv7` |
| [UHF Server](./uhf-server) | DVR recording server for the UHF app, with recordings stored in the Home Assistant media folder. | `amd64`, `aarch64` |

## Notes

- Each add-on is a thin wrapper around the official upstream image, pinned to an
  exact release tag rather than `latest`, or by digest where upstream publishes
  no releases:
  [`ghcr.io/viren070/aiostreams`](https://github.com/Viren070/AIOStreams),
  [`ghcr.io/dispatcharr/dispatcharr`](https://github.com/Dispatcharr/Dispatcharr),
  [`ghcr.io/lostb1t/remux`](https://github.com/lostb1t/remux),
  [`ghcr.io/tvheadend/tvheadend`](https://github.com/tvheadend/tvheadend) and
  [`swapplications/uhf-server`](https://github.com/swapplications/uhf-server-dist).
- Version bumps are proposed by a scheduled workflow as pull requests, and are
  merged by hand so each upstream release gets reviewed.
- The AIOStreams, Dispatcharr, Remux and Tvheadend icons and logos are derived
  from their upstream logos (AIOStreams GPL-3.0, Dispatcharr AGPL-3.0, Remux
  AGPL-3.0, Tvheadend GPL-3.0). UHF Server ships no branding assets, so that
  add-on has none.
- This repository carries no licence.

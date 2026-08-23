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
| [UHF Server](./uhf-server) | DVR recording server for the UHF app, with recordings stored in the Home Assistant media folder. | `amd64`, `aarch64` |

## Notes

- Each add-on is a thin wrapper around the official upstream image, pinned to an
  exact release tag rather than `latest`:
  [`ghcr.io/viren070/aiostreams`](https://github.com/Viren070/AIOStreams) and
  [`swapplications/uhf-server`](https://github.com/swapplications/uhf-server-dist).
- Version bumps are proposed by a scheduled workflow as pull requests, and are
  merged by hand so each upstream release gets reviewed.
- The AIOStreams icon and logo are derived from the upstream AIOStreams logo
  (AIOStreams is GPL-3.0 licensed). UHF Server ships no branding assets, so that
  add-on has none.
- This repository carries no licence.

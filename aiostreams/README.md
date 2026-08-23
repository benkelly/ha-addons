# AIOStreams

Home Assistant add-on wrapping the official
[AIOStreams](https://github.com/Viren070/AIOStreams) image
(`ghcr.io/viren070/aiostreams`).

AIOStreams consolidates multiple Stremio addons and debrid services, including
its own built-in addons, into a single customisable super-addon.

Supported architectures: `amd64`, `aarch64`.

See [DOCS.md](./DOCS.md) for setup and the full option reference.

## Quick start

1. Install the add-on and open the **Configuration** tab.
2. Set `SECRET_KEY` to a 64 character hex string
   (`openssl rand -hex 32`). The add-on refuses to start without it.
3. Set `BASE_URL` to the address you reach the add-on on, for example
   `http://homeassistant.local:3000`.
4. Start the add-on and click **Open Web UI**.

Everything else is configured from the AIOStreams dashboard itself.

## Branding assets

`icon.png` and `logo.png` are downscaled from the upstream AIOStreams logo
shipped inside the official image. AIOStreams is GPL-3.0 licensed.

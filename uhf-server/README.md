# UHF Server

Home Assistant add-on wrapping the official
[UHF Server](https://github.com/swapplications/uhf-server-dist) image
(`swapplications/uhf-server`).

UHF Server is the DVR recording backend for the UHF app. It records streams,
optionally detects commercials with comskip, and serves recordings back as HLS.

Supported architectures: `amd64`, `aarch64`. Both are published upstream and
were checked against the image manifest.

See [DOCS.md](./DOCS.md) for setup and the full option reference.

## Quick start

1. Install the add-on.
2. Set a `password` in the **Configuration** tab. The server has no
   authentication by default.
3. Start the add-on.
4. In the UHF app, add the server by IP address and port, for example
   `192.168.1.10:8000`.

Recordings are written to `/media/uhf-recordings`, so they appear in the Home
Assistant media browser.

## Note

This add-on has no web interface. UHF Server is an API only service consumed
by the UHF app, so there is no **Open Web UI** button.

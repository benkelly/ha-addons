# AIOStreams

Thin wrapper around the official `ghcr.io/viren070/aiostreams` image, pinned to
an exact upstream release tag.

## Setup

1. Add this repository to Home Assistant, then install **AIOStreams**.
2. Generate an encryption secret:

   ```
   openssl rand -hex 32
   ```

3. Open the **Configuration** tab and set `SECRET_KEY` to that value.
   The add-on will not start without it.
4. Set `BASE_URL` to the address you actually reach the add-on on, including
   the scheme and port, for example `http://homeassistant.local:3000` or
   `https://aiostreams.example.com` if you put it behind a reverse proxy.
5. Start the add-on and open the web UI on port `3000`.

Only the options below are set through Home Assistant. Everything else, such as
presets, debrid credentials, proxying, caching and rate limits, is a runtime
setting configured from the AIOStreams dashboard and stored in the database.

## Options

### `SECRET_KEY` (required)

Secret used to encrypt stored addon configurations. Must be a 64 character hex
string. Generate one with `openssl rand -hex 32`.

Do not change this after the first run. Changing it makes every configuration
already stored in the database undecryptable.

### `BASE_URL`

Public base URL of the addon, including scheme, hostname and port. Used to
generate installation URLs, genre links and built-in addon stream URLs, so
Stremio clients must be able to reach it.

Upstream requires this. If you leave it blank the add-on falls back to
`http://homeassistant.local:3000`, which suits a default Home Assistant OS
install but is wrong if you reach Home Assistant on another address.

### `ADDON_NAME`

Display name of the addon in Stremio. Leave blank to keep the default and to
keep the field editable from the dashboard. Setting it here pins the value and
makes it read-only in the UI.

### `DATABASE_URI`

Overrides the database location. Leave blank to use the SQLite database in
`/data`, which is the right choice for almost everyone. Set it to a
`postgres://user:password@host:port/database` URI to use PostgreSQL instead.

### `AIOSTREAMS_AUTH`

Operator credentials for this instance, as comma separated `username:password`
pairs, for example `alice:hunter2,bob:swordfish`. Leave blank to leave the
instance unprotected.

### `AIOSTREAMS_AUTH_PERMISSIONS`

Per user permissions, as comma separated `username=perm1|perm2` entries. Valid
permissions are `admin`, `proxy`, `service`, `sabnzbd` and `none`. Users not
listed default to `admin`. Example:
`alice=admin,bob=proxy|sabnzbd,carol=none`.

### `REDIS_URI`

Redis connection URI. Only worth setting when running several instances. A
single add-on uses a faster internal memory cache, so leave this blank.

### `LOG_LEVEL`

One of `error`, `warn`, `info`, `http`, `verbose`, `debug`, `silly`.
Defaults to `info`.

### `LOG_FORMAT`

`text` or `json`. Defaults to `text`, which reads better in the Home Assistant
add-on log.

### `SYSTEM_LIFECYCLE_ENABLED`

Allows the dashboard System page to stop the AIOStreams process. Defaults to
`false`. The Supervisor restarts the add-on anyway, so leave it off unless you
have a reason not to.

## Data and persistence

All persistent state lives in `/data`, which survives add-on restarts and
updates:

- `/data/db.sqlite`, the configuration database
- `/data/cache`, the disk backed caches for usenet segments, NZBs and torrent
  metadata
- `/data/options.json`, the add-on options written by the Supervisor

The add-on sets `DATABASE_URI` and `DISK_CACHE_DIR` for you, so nothing is
written to the container filesystem. Uninstalling the add-on removes `/data`,
so back up `/data/db.sqlite` first if you want to keep your configuration.

## Networking

The web interface is exposed on port `3000`. Change the host side of the
mapping in the **Network** section of the add-on page if `3000` is taken. If
you do, update `BASE_URL` to match.

## Updates

Updates are manual tag bumps. The Dockerfile pins an exact upstream release
tag, never `latest`, so a rebuild always produces the same version.

A scheduled workflow checks for new upstream releases daily and opens a pull
request bumping the pinned tag, the add-on version and the changelog. Each bump
is reviewed and merged by hand, and Home Assistant then offers the update in
the usual way.

## Troubleshooting

**The add-on stops straight away.** Check the log. A missing or malformed
`SECRET_KEY` is the usual cause and is reported explicitly.

**Install URLs point at the wrong host.** `BASE_URL` is wrong. Set it to the
address your Stremio clients use and restart.

**Configurations stopped decrypting after a change.** `SECRET_KEY` was changed
after the first run. Restore the previous value.

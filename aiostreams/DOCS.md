# AIOStreams

Thin wrapper around the official `ghcr.io/viren070/aiostreams` image, pinned to
an exact upstream release tag.

## Setup

1. Add this repository to Home Assistant, then install **AIOStreams**.
2. Open the **Configuration** tab and set `BASE_URL` to the address you actually
   reach the add-on on, including the scheme and port, for example
   `http://homeassistant.local:3000`, or `https://aiostreams.example.com` if you
   put it behind a reverse proxy.
3. Start the add-on and open the web UI on port `3000`.

`SECRET_KEY` is generated for you on the first start, so you only need to touch
it if you want to supply your own.

Only the options below are set through Home Assistant. Everything else, such as
presets, debrid credentials, proxying, caching and rate limits, is a runtime
setting configured from the AIOStreams dashboard and stored in the database.

## Options

### `SECRET_KEY`

Secret used to encrypt stored addon configurations. A 64 character hex string.

**You can leave this blank.** On the first start the add-on generates a key,
saves it to the add-on options through the Supervisor, and uses it. It then
appears in this Configuration tab like any other setting, so there is nothing
to do unless you want to supply your own. To do that, generate one with
`openssl rand -hex 32` and paste it in before the first start.

A copy is also kept in `/data/secret_key`. That copy is what gets reused if the
add-on cannot reach the Supervisor, so the add-on still starts and keeps
working either way.

Do not change the key once the add-on has run. Changing it makes every
configuration already stored in the database undecryptable. The add-on logs a
warning if it spots the key has changed from the one it generated.

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
instance unprotected. It is read at startup only, so restart the add-on after
changing it.

Each pair splits on its first colon, so a password may contain colons but not
commas, and leading or trailing spaces are stripped. Both halves must be
non-empty or the add-on refuses to start.

### `AIOSTREAMS_AUTH_PERMISSIONS`

Per user permissions, as comma separated `username=perm1|perm2` entries. Users
you do not list keep full admin, so only list the ones you want to limit.

Valid permissions are `admin`, `proxy`, `service`, `sabnzbd`, `createConfig`
and `none`. `admin` implies all the others. `none` grants nothing and cannot be
combined with anything else.

Watch out for `createConfig`. Listing a user without it stops them creating new
configurations, and it is easy to leave out because it was added after the
other permissions. Include it unless you mean to withhold it:

```
alice=admin,bob=createConfig|proxy|sabnzbd,carol=none
```

The add-on logs a warning naming any user whose entry is missing it.

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
- `/data/secret_key`, the fallback copy of a generated `SECRET_KEY`

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

**The add-on stops straight away.** Check the log. A malformed `SECRET_KEY`
that you set yourself is the usual cause and is reported explicitly. A blank
one is not a problem, it gets generated.

**Install URLs point at the wrong host.** `BASE_URL` is wrong. Set it to the
address your Stremio clients use and restart.

**Configurations stopped decrypting after a change.** `SECRET_KEY` was changed
after the first run. Restore the previous value.

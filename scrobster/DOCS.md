# scrobSter

Runs the pre-built `ghcr.io/benkelly/scrobster` image, pinned to an exact tag.
Nothing is compiled on your device.

## How it works

Every `match_interval` seconds the add-on records `chunk_seconds` of audio from
the microphone. It builds an audio signature on the device and asks Shazam to
identify it. Only the signature leaves your network, never the recording.

A match does two things. It marks the track as playing now, so your profile
shows the live line while the song continues. It also scrobbles the track once
per play.

A track that keeps playing is not scrobbled twice. A track that restarts is
scrobbled again, because Shazam reports the position inside the track and that
position drops back on a repeat.

## Audio

This is the part that decides whether the add-on works.

1. Open the add-on **Audio** setting.
2. Choose your microphone under **Input**.
3. Restart the add-on.

Home Assistant passes that choice to the add-on, so leave `audio_device` at
`default`. Only change it if you want a specific PulseAudio source by name.

You can also pick the input in the web page. Sign in as an administrator, open
**Settings**, and use **Audio input**. It lists the devices ffmpeg can see, and
**Test level** records three seconds from the one you pick and reports the
peak, so a silent input is caught before you keep it. That choice is saved and
outranks `audio_device`, and **Reset** hands control back to the option.

Any input that Home Assistant lists works, including a USB microphone and a USB
sound card with a line input. A line input from a radio or an amplifier gives
the best results, because it avoids room noise altogether.

## Accounts

The first start creates one administrator. Set `admin_password` to choose its
password. Without one, a random password is written to the add-on log once, so
read the log and then change it under Settings.

`admin_password` applies on every start, not only the first one. If you forget
the password, set this option, restart, and sign in with the new value.

Through **Open Web UI** there is no sign-in, because Home Assistant has already
signed you in and its rules say an add-on must not ask twice. A sign-in appears
only when you reach the add-on another way, such as through a reverse proxy.

An administrator adds more people under **Users**. Each person then connects
their own services under **Settings**, and their history is their own.

Only an administrator starts or stops the microphone.

## Connect a service

You can set these options, which seed the first account on the first start.
After that, manage services in the web page under **Settings**, because they
belong to a user rather than to the add-on.

Set at least one. You can set several, and every match goes to all of them.

### ListenBrainz

The quickest. Copy your token from
<https://listenbrainz.org/settings/> into `listenbrainz_token`.

### Maloja

Set `maloja_url` to your server, for example `http://192.168.1.10:42010`, and
`maloja_key` to an API key from that server.

### Last.fm

Last.fm needs an API key, which identifies scrobSter itself and is shared by
everybody on this add-on. Each person then authorizes their own account in the
browser. scrobSter never stores your password.

1. Create an API account at <https://www.last.fm/api/account/create>.
2. Put the key in `lastfm_api_key` and the secret in `lastfm_api_secret`, then
   restart the add-on.
3. Open the web page, go to **Settings**, and select **Connect** beside
   Last.fm.
4. Approve scrobSter in the tab that opens, then select **I approved it**.

Every user repeats steps 3 and 4 for their own Last.fm account.

### Libre.fm

Set `librefm_username` and `librefm_password`. The add-on hashes the password
on the first start and keeps only the hash.

If you would rather not give the add-on the password itself, set
`librefm_password_hash` to the md5 hash instead:

```sh
printf '%s' 'your-password' | md5sum
```

## Options

### `audio_backend`

`pulse` or `alsa`. Leave this at `pulse`. Home Assistant provides its audio
system through PulseAudio, and the input you choose in the **Audio** setting
only applies to `pulse`.

### `audio_device`

The input to record. `default` follows the **Audio** setting, which is what you
want. A PulseAudio source name also works, for example
`alsa_input.usb-0d8c_USB_Audio-00.analog-stereo`. A device chosen under
**Settings** in the web page outranks this option.

### `chunk_seconds`

Seconds of audio per attempt. Defaults to `12`, and the maximum is `14`.

Do not assume that more is better. Windows of 8 to 14 seconds match, but 16 and
20 seconds fail every time, even though their signatures hold more data.

### `match_interval`

Minimum seconds between attempts. Defaults to `15`. Raise it if Shazam
rate-limits your address. Silence costs nothing, because the add-on skips the
request when it hears nothing.

### `rescrobble_minutes`

Fallback only, and rarely used. It applies when a match arrives without a track
position. Defaults to `30`.

### `now_playing_stop_seconds`

Clear the playing-now mark after this long with no match. Defaults to `180`.

Keep it well above one song. Matches drop out during quiet passages, so a short
value makes the mark flicker while a song is still playing. ListenBrainz and
Maloja are cleared through an API call. Last.fm has no method to clear a mark,
so its copy disappears a few minutes later on its own.

### `api_token`

Optional. When set, the JSON API needs the header
`Authorization: Bearer <token>`.

Leave this empty while you reach the add-on only through ingress. Home
Assistant already authenticates you, and a token makes the built-in page ask
for it again.

**Set it if you publish the add-on through a reverse proxy.** Without a token
the API is open to anyone who reaches the address. `POST /api/match` accepts
audio and scrobbles the result, so a stranger could write tracks into your
listening history. `POST /api/listen` can also stop the add-on.

The web page asks for the token once and keeps it in browser storage.

## The web page

Use **Open Web UI**. The page shows the current match, the input level, the
scrobble history, and which service accepted each scrobble.

It also has a **use this device's mic** button. That records from the browser
instead of the add-on, which is useful from a phone in a different room. Once
the browser has granted permission, a menu beside the button chooses which
microphone, and the page remembers it. Both inputs share one history and one
duplicate filter.

That button needs a secure context, which is a browser rule and not a Home
Assistant one. It works when you reach Home Assistant over `https`, for example
through Nabu Casa or your own certificate. Over a plain `http` address the
browser blocks the microphone, and the button reports that. The add-on
microphone is not affected and keeps working either way.

## Use matches in Home Assistant

The add-on serves a JSON status endpoint, so you can turn what it hears into a
sensor and use it in automations.

Ingress cannot be read by a sensor, so map a port first. Open the add-on
**Network** setting, set the host port for `8000/tcp` to `8000`, and restart.

Then add this to `configuration.yaml`:

```yaml
sensor:
  - platform: rest
    name: scrobSter
    resource: http://homeassistant.local:8000/api/status
    scan_interval: 30
    value_template: >-
      {{ value_json.last_match.artist ~ ' - ' ~ value_json.last_match.title
         if value_json.last_match else 'nothing' }}
    json_attributes:
      - last_match
      - listening
      - level_db
      - services
```

Use the IP address of your Home Assistant machine if `homeassistant.local`
does not resolve. Set `api_token` to nothing while you do this, because the
sensor sends no token.

The attributes carry the detail. `last_match` holds the artist, title, album,
cover art URL and the position inside the track. `level_db` is the input level,
which is useful for an alert when the microphone goes silent:

```yaml
automation:
  - alias: Warn when scrobSter hears nothing
    trigger:
      - platform: numeric_state
        entity_id: sensor.scrobster
        attribute: level_db
        below: -80
        for: "00:10:00"
    action:
      - service: notify.persistent_notification
        data:
          message: scrobSter input has been silent for ten minutes.
```

The sensor reports the last match, which stays after the song ends. Use the
`last_match.ts` attribute, a unix timestamp, when you need to know how recent
it is.

## Troubleshooting

**Nothing is ever matched.** Read `input <n> dBFS` on the page.

- About -91 dBFS means the input is silent. Choose a different input under the
  **Audio** setting.
- About -20 dBFS means the microphone hears the room, but the sound is too poor
  to identify. Raise the volume, or move the microphone closer.

**Some songs never match.** That is normal. Speech, quiet passages, live
versions and obscure recordings do not match. Shazam tolerates a lot of noise,
so a missed song is usually one of those rather than a volume problem.

**Scrobbles are missing from one service only.** The history table shows a
badge per service for every scrobble. A red badge carries the error, so check
the credentials for that service.

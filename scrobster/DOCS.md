# scrobSter

Runs the pre-built `ghcr.io/benkelly/scrobster` image, pinned to an exact tag.
Nothing is compiled on your device.

## How it works

Every `match_interval` seconds the add-on records `chunk_seconds` of audio in
each room: the microphone, and any camera you add. It builds an audio signature
on the device and asks Shazam to identify it. Only the signature leaves your
network, never the recording.

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

The microphone is the first room, named "Server mic". To pick another input in
the web page, open **Rooms** as an administrator and select **Edit** on that
room. The form lists the devices ffmpeg can see, and **Test level** records
three seconds from the one you pick and reports the peak, so a silent input is
caught before you keep it. A device chosen there outranks `audio_device`;
**Default from the environment** hands control back to the option.

Any input that Home Assistant lists works, including a USB microphone and a USB
sound card with a line input. A line input from a radio or an amplifier gives
the best results, because it avoids room noise altogether.

## Rooms and cameras

Each room is one input: the microphone, or a camera. The **Rooms** tab shows
every room with its live level and what it hears. Rename "Server mic" after the
room it is in with **Edit**.

To add a camera, open **Rooms** as an administrator and fill in **Add a room**:

1. Give it a name, for example `Kitchen`.
2. Under **Listens through**, choose **A camera or stream**.
3. Paste the camera's URL, for example
   `rtsps://192.168.1.1:7441/abcdEFGH?enableSrtp` from UniFi Protect, or
   `rtsp://user:password@192.168.1.20:554/stream2`.
4. Select **Test level**. A camera that hears sound reports a peak. A camera
   with its audio turned off says so.
5. Select **Add room**.

The add-on asks the camera for its audio only, so no video is downloaded.

Tips:

- **Turn on the camera's audio**, and choose AAC at 16 kHz or more if the camera
  offers it. G.711 at 8 kHz cuts the sound Shazam relies on, and matches less
  often.
- **If you run Frigate or go2rtc**, use its restream, for example
  `rtsp://homeassistant.local:8554/kitchen`. Many cameras accept only a few
  connections at once.
- **The camera password stays in the add-on.** The page shows it as `***`.
  Leave the `***` in place when you edit the URL, and the saved password is
  kept.

Each person turns on **scrobble for me** for the rooms they want. A room
scrobbles for nobody until then, except for the administrator who added it. A
song that two rooms hear at once is still one play.

Every room asks Shazam from the same address, so requests take turns, at most
one per `recognition_gap_seconds`. A room that hears silence asks nothing.

To tune that without a restart, open **Rooms** as an administrator and use
**Recognition** at the bottom. It sets the seconds between Shazam requests and
between listens in each room, and a change applies at once. It also counts the
requests of the last ten minutes, says when Shazam last limited them, and warns
when your rooms would want requests faster than the limit allows. A choice made
there outranks the two options below, until **Back to the configured rates**.

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

Only an administrator starts or stops listening, and adds or changes rooms.

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
`alsa_input.usb-0d8c_USB_Audio-00.analog-stereo`. A device chosen for a room
on the **Rooms** tab outranks this option.

### `chunk_seconds`

Seconds of audio per attempt. Defaults to `12`, and the maximum is `14`.

Do not assume that more is better. Windows of 8 to 14 seconds match, but 16 and
20 seconds fail every time, even though their signatures hold more data.

### `match_interval`

Minimum seconds between attempts, in each room. Defaults to `15`. Raise it if
Shazam rate-limits your address. Silence costs nothing, because the add-on
skips the request when it hears nothing. **Recognition** on the **Rooms** tab
outranks this option.

### `recognition_gap_seconds`

Minimum seconds between two Shazam requests, across every room and browser
clip. Defaults to `4`. Requests wait their turn, so adding rooms does not add
to the rate. Raise it if Shazam rate-limits your address while several rooms
hear music at once. **Recognition** on the **Rooms** tab outranks this option.

### `skip_known_seconds`

Once a room matches the same song twice in a row, it stops asking Shazam until
that song should end, and for at most this many seconds. Defaults to `60`. The
song's length comes from MusicBrainz, and the room asks again a few seconds
before the end, so the next song is caught as it starts. Silence makes the room
ask again at once.

While music plays this saves most requests, so more rooms and cameras fit
within Shazam's limit. The cost is that a song changed half-way through is
noticed up to this many seconds late. Set `0` to ask every cycle.

### `rescrobble_minutes`

Fallback only, and rarely used. It applies when a match arrives without a track
position. Defaults to `30`.

### `now_playing_stop_seconds`

Clear the playing-now mark after this long with no match. Defaults to `180`.

Keep it well above one song. Matches drop out during quiet passages, so a short
value makes the mark flicker while a song is still playing. ListenBrainz and
Maloja are cleared through an API call. Last.fm has no method to clear a mark,
so its copy disappears a few minutes later on its own.

### `mqtt_enabled`

Publish the rooms and users as Home Assistant devices, through the Mosquitto
broker add-on. On by default. Without a broker the add-on writes one warning to
its log and carries on. See **Devices in Home Assistant**.

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

Use **Open Web UI**. **Listening** shows the current match, the scrobble
history, and which service accepted each scrobble. **Rooms** shows each room's
input level and what it hears.

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

## Devices in Home Assistant

The add-on publishes every room and every user as a device, through MQTT. Each
one has its own entities, which you can put on a dashboard and use in
automations, with no YAML.

1. Install the **Mosquitto broker** add-on from the official add-on store, and
   start it.
2. Home Assistant offers to set up the **MQTT** integration. Accept.
3. Restart scrobSter. The add-on log says `MQTT: connected`.

The add-on gets the broker and its credentials from Home Assistant, so there is
nothing to type. The devices appear under **Settings** > **Devices & services**
> **MQTT**.

| Device | Entities |
|---|---|
| **scrobSter** | **Listening**, to start and stop every room. **Shazam rate limit** and **Shazam requests (10 min)**. The two recognition rates, as numbers |
| **scrobSter Kitchen**, one per room | **Now playing**: `Artist - Title`, or `idle`, with the album and cover as attributes. **Cover art**. **Music**, on while a song plays. **Input level** in dBFS. **Recording**. **Problem**, on while the room keeps failing. **Last error**. **Listen here**, to turn the room on and off. **Match**, an event |
| **scrobSter sam**, one per user | **Last scrobble**. **Scrobbles today**. **Services**. A **Scrobble** switch for each room, the same as **scrobble for me** |

A room's device is placed in the Home Assistant area with the room's name, so
name your rooms after your areas. A room or user you delete disappears from
Home Assistant too.

When the add-on stops, its entities show as unavailable.

### Automations

**Match** fires when a room starts hearing a song: a new track, or the same one
after `now_playing_stop_seconds` of quiet. It does not fire again while the song
plays. Its attributes carry `artist`, `title`, `album`, `art_url`, `room` and
`users`:

```yaml
automation:
  - alias: Dim the kitchen for Daft Punk
    triggers:
      - trigger: state
        entity_id: event.scrobster_kitchen_match
    conditions:
      - condition: template
        value_template: "{{ trigger.to_state.attributes.artist == 'Daft Punk' }}"
    actions:
      - action: light.turn_on
        target: {entity_id: light.kitchen}
        data: {brightness_pct: 30}
```

To be told when a camera drops, watch its room's **Problem** sensor:

```yaml
automation:
  - alias: Tell me when the bedroom camera is down
    triggers:
      - trigger: state
        entity_id: binary_sensor.scrobster_master_bedroom_problem
        to: "on"
        for: "00:10:00"
    actions:
      - action: notify.persistent_notification
        data:
          message: >-
            The bedroom camera has been failing since
            {{ state_attr('binary_sensor.scrobster_master_bedroom_problem', 'failing_since') }}.
```

To be told when a microphone goes quiet, watch its **Input level**:

```yaml
automation:
  - alias: Warn when the kitchen hears nothing
    triggers:
      - trigger: numeric_state
        entity_id: sensor.scrobster_kitchen_input_level
        below: -80
        for: "00:10:00"
    actions:
      - action: notify.persistent_notification
        data:
          message: The kitchen microphone has been silent for ten minutes.
```

To have a room scrobble for whoever is home, turn that person's switch on and
off from their presence:

```yaml
automation:
  - alias: Scrobble the kitchen for sam while sam is home
    triggers:
      - trigger: state
        entity_id: person.sam
    actions:
      - action: >-
          switch.turn_{{ 'on' if trigger.to_state.state == 'home' else 'off' }}
        target: {entity_id: switch.scrobster_sam_scrobble_kitchen}
```

### Who can control it

The switches and numbers act like an administrator. Anybody who can change
entities in Home Assistant can start and stop listening, change the rates, and
choose rooms for any user, as anybody who opens the add-on through **Open Web
UI** already can. Camera URLs and service credentials are never published.

The broker is what lets the commands in, so keep it private: the Mosquitto
add-on only accepts Home Assistant users and add-ons.

To publish nothing, turn off `mqtt_enabled`.

## Use matches in a REST sensor

Without MQTT, the add-on still serves a JSON status endpoint that you can read
into a sensor.

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
cover art URL, the position inside the track, and the room that heard it.
`level_db` is the input level of the first room, which is useful for an alert
when the microphone goes silent:

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

For a sensor per room, add `rooms` to `json_attributes`, or use this
`value_template` for the kitchen:

```yaml
    value_template: >-
      {% set room = value_json.rooms | selectattr('name', 'eq', 'Kitchen') | first %}
      {{ room.last_match.title if room and room.last_match else 'nothing' }}
```

The sensor reports the last match, which stays after the song ends. Use the
`last_match.ts` attribute, a unix timestamp, when you need to know how recent
it is.

## Troubleshooting

**Nothing is ever matched.** Read the room's level on the **Rooms** tab.

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

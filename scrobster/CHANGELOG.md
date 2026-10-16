# Changelog

## 0.4.0

- Update scrobSter to [v0.4.0](https://github.com/benkelly/scrobSter/releases/tag/v0.4.0).
- Each room's meter on the **Rooms** tab now moves a few times a second while
  the room records, instead of once a cycle. Between two recordings it holds
  its last value.
- A room's cover art is larger, with the title and the artist on two lines. On
  a phone the meter sits under the track.
- The web page uses the new pug icon. No option changes.

## 0.3.1

- Update scrobSter to [v0.3.1](https://github.com/benkelly/scrobSter/releases/tag/v0.3.1).
- Tune how often Shazam is asked, in the web page and without a restart. An
  administrator finds **Recognition** at the bottom of the **Rooms** tab, with
  the seconds between Shazam requests and the seconds between listens in each
  room. A choice made there outranks `recognition_gap_seconds` and
  `match_interval` until **Back to the configured rates**.
- The card counts the Shazam requests of the last ten minutes, says when Shazam
  last limited them, and warns when your rooms would want requests faster than
  the limit allows.

## 0.3.0

- Update scrobSter to [v0.3.0](https://github.com/benkelly/scrobSter/releases/tag/v0.3.0).
- Listen in more than one room, including the audio of your cameras. A new
  **Rooms** tab lists each room with its live level and what it hears. A room
  is a microphone or a camera's `rtsp://` or `rtsps://` stream, UniFi Protect
  included.
- Each person chooses which rooms scrobble for them, with **scrobble for me**.
  A song that two rooms hear at once is still one play.
- The history shows the room that heard each song.
- A camera password stays in the add-on. The page shows it as `***`, and
  errors are cleaned of it.
- New option `recognition_gap_seconds`: every room shares one Shazam budget,
  at most one request per this many seconds. Defaults to `4`.
- The microphone becomes the first room, named "Server mic", with the input
  you chose in the web page. Rename it after the room it is in. The
  **Settings**, **Audio input** card moved into the **Rooms** tab.
- For a REST sensor, `/api/status` keeps its fields and adds `rooms`.

## 0.2.6

- Update scrobSter to [v0.2.6](https://github.com/benkelly/scrobSter/releases/tag/v0.2.6).
- ListenBrainz and Maloja now receive MusicBrainz IDs, found from the ISRC
  that Shazam returns. ListenBrainz uses them to show the album's cover from
  the Cover Art Archive.
- Maloja now gets Shazam's cover for an album that only shows a placeholder.
  A picture Maloja already has is never replaced.
- Last.fm and Libre.fm are unchanged: they have no way to receive artwork.

## 0.2.5

- Update scrobSter to [v0.2.5](https://github.com/benkelly/scrobSter/releases/tag/v0.2.5).
- Security: a reverse proxy on the same host that passed `X-Forwarded-For`
  through let anyone pose as Home Assistant ingress and be signed in as the
  owner. The header is no longer trusted. The add-on itself was not exposed.
- A clip from one person's browser microphone no longer shows on everyone
  else's page or in their Home Assistant sensor.
- Changing a password, or resetting one, signs that account out everywhere
  else.
- The last administrator can no longer remove their own role.
- A Shazam rate limit no longer stalls listening for about twelve minutes. The
  add-on waits and tries again, and says it is rate limited.
- A microphone that opens but sends no audio no longer hangs listening for
  good, and stopping no longer leaves the device busy.
- A scrobbling service that is down no longer holds up the others.
- A Last.fm or Libre.fm password changed in Settings takes effect without a
  restart.
- Old sign-ins and records that only ever grew are now cleaned up.

## 0.2.4

- Update scrobSter to [v0.2.4](https://github.com/benkelly/scrobSter/releases/tag/v0.2.4).

## 0.2.3

- Pick the microphone in the web page. An administrator opens **Settings**,
  **Audio input**, and chooses from the devices ffmpeg can see. **Test level**
  records three seconds from a device and reports its peak, so a silent input
  is caught before you keep it. The choice is saved and outranks the
  `audio_device` option.
- Choose which microphone the browser uses, when you scrobble from a phone or a
  laptop with **use this device's mic**. The page remembers the choice.
- Clearer status on the page. It says what the add-on is doing, and errors
  appear in place instead of in a browser dialog you have to dismiss.
- The page now works on a phone.
- Set `librefm_password` and let the add-on hash it. Only the hash is kept, so
  running `md5sum` by hand is no longer necessary. `librefm_password_hash`
  still works.

## 0.2.2

- Fix `admin_password` doing nothing when the account already existed. Setting
  it after the first start left the old random password in place, so the
  administrator could not sign in. It is now applied on every start, which also
  gives a way back in after a forgotten password.
- An administrator can set a password for another account, under **Users**.

## 0.2.1

- Accounts. Each person signs in and connects their own scrobbling services in
  the web page, under Settings.
- The room microphone is shared, so each user chooses whether to receive what it
  hears. That choice starts off, because a room microphone cannot tell who is
  listening.
- Last.fm is now authorized in the browser. The command line step is gone.
- Only an administrator starts or stops the microphone.
- Set `admin_password` to choose the first password. Without it, a random one is
  written to the log on the first start.
- Through ingress there is no second sign-in, because Home Assistant has already
  signed you in.
- The service options below now only seed the first account. After that, manage
  them in Settings.

## 0.1.2

- Fix the add-on ignoring `audio_backend` and `audio_device`. The image pinned
  both as environment variables, which outrank the add-on options, so the
  microphone was always read through ALSA.
- Add the ALSA to PulseAudio plugin, so `audio_backend: alsa` also works with
  the sound routing that Home Assistant provides.

## 0.1.1

- Fix the add-on failing to start with `unable to open database file`. The
  container ran as an unprivileged user, but Home Assistant provides `/data` as
  a root-owned bind mount, so the database could not be created.

## 0.1.0

- Initial release, wrapping scrobSter
  [v0.1.0](https://github.com/benkelly/scrobSter/releases/tag/v0.1.0).
- Takes the microphone from the Home Assistant audio system, so the input is
  chosen in the add-on **Audio** setting.
- Ingress, so the page needs no open port.

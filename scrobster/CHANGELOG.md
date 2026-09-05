# Changelog

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

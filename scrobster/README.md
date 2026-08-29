# scrobSter

Home Assistant add-on for [scrobSter](https://github.com/benkelly/scrobSter),
running the pre-built image `ghcr.io/benkelly/scrobster`.

scrobSter listens to a microphone, identifies the music with Shazam, and
scrobbles what it hears to Last.fm, Libre.fm, ListenBrainz or Maloja. Point it
at a radio, a record player or a television and your listening history fills
itself in.

Supported architectures: `amd64`, `aarch64`.

See [DOCS.md](./DOCS.md) for setup and the full option reference.

## Quick start

1. Install the add-on.
2. Open the **Audio** setting and choose your microphone as the input.
3. Put at least one service credential in the configuration. A ListenBrainz
   token is the quickest, because it is a single value.
4. Start the add-on and click **Open Web UI**.
5. Play music. Read `input <n> dBFS` on the page to confirm that the
   microphone hears it.

## What to expect

A match needs a clear recording. Shazam copes with a noisy room, but it cannot
identify speech, a quiet passage or a live version that is not in its database.
Expect gaps on a television, and few gaps on a radio playing chart music.

The page shows the input level. Use it to place the microphone: about -20 dBFS
while music plays is healthy, and -91 dBFS means the input is silent.

## Where this fits

This add-on is for sound in a room, from a source that cannot scrobble on its
own. If your music comes from Spotify, Plex or Music Assistant, use their own
scrobbling instead. Those know exactly what is playing, so they are always
more accurate than a microphone.

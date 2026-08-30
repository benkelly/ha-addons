# Changelog

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

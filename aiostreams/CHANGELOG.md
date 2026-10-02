# Changelog

## 2.35.7

- Update AIOStreams to [v2.35.7](https://github.com/Viren070/AIOStreams/releases/tag/v2.35.7).

## 2.35.4

- Update AIOStreams to [v2.35.4](https://github.com/Viren070/AIOStreams/releases/tag/v2.35.4).

## 2.35.3

- Update AIOStreams to [v2.35.3](https://github.com/Viren070/AIOStreams/releases/tag/v2.35.3).

## 2.35.2

- Update AIOStreams to [v2.35.2](https://github.com/Viren070/AIOStreams/releases/tag/v2.35.2).

## 2.35.0

- Update AIOStreams to [v2.35.0](https://github.com/Viren070/AIOStreams/releases/tag/v2.35.0).

## 2.34.1

- Update AIOStreams to [v2.34.1](https://github.com/Viren070/AIOStreams/releases/tag/v2.34.1).

## 2.34.0

- Update AIOStreams to [v2.34.0](https://github.com/Viren070/AIOStreams/releases/tag/v2.34.0).

## 2.33.2-1

- Generate `SECRET_KEY` on the first start when it is left blank, and save it
  to the add-on options so it shows up in the Configuration tab. The add-on no
  longer refuses to start with an empty key.
- Keep a fallback copy of a generated key in `/data/secret_key`, used if the
  Supervisor cannot be reached.
- Warn when `SECRET_KEY` no longer matches the generated key, since stored
  configurations will not decrypt.

## 2.33.2

- Initial release, wrapping AIOStreams
  [v2.33.2](https://github.com/Viren070/AIOStreams/releases/tag/v2.33.2).

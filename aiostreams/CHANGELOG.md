# Changelog

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

# Berth CLI

Use Berth with no website. One Python 3 script. No pip install.

```sh
curl -fsSL https://atberth.com/install.sh | sh
berth login
berth apps create demo
berth tables create --app demo notes body:text
berth rows add --app demo notes body=hello
```

API base: `https://api.atberth.com/v1`

`berth login` asks for a token, or takes `--token`. You can also pipe a token file. The token is saved at `~/.config/berth/config.json` (mode 600).

`berth apps create` prints the app token once and stores it in that same file.

Add `--json` to any command for script output. Every command has `--help`.

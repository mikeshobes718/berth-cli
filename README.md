# Berth CLI

Use Berth with no website. One Python 3.9+ script, standard library only, no pip install.

```sh
curl -fsSL https://atberth.com/install.sh | sh
berth signup --email you@example.com      # or: berth login --email you@example.com
berth apps create demo
berth use demo
berth tables create notes title:text:notnull done:boolean --read public
berth rows add notes title=hello done=false
berth rows list notes --where done.eq=false
```

The installer puts `berth` in `~/.local/bin`. Set `BERTH_INSTALL_DIR` to install somewhere else.

API base: `https://api.atberth.com/v1`. The contract is in the server's `SPEC.md`, and `GET /v1/openapi.json` lists every route.

## Security

- **Never ship a secret key (`bsk_`) or account key (`bak_`) in a phone, browser, or desktop app.** Anyone can pull it out of the build and get full access to your data. Apps get the **publishable key (`bpk_`)** only, and table and bucket policies decide what it can do.
- Secret keys belong on your server, in CI, and in Berth functions (they get `BERTH_SECRET_KEY` injected).
- Keys are shown once, when they are created. `berth apps create`, `berth apps restore`, and `berth keys create` save them for you.
- Credentials are saved in `~/.config/berth/config.json` (file mode 600, folder mode 700). Do not commit it.

## Global options and environment

Every command and subcommand has `--help` with an example.

| Option or variable | Meaning |
| --- | --- |
| `--json` | Print the raw API JSON. Works before or after the subcommand. |
| `--api URL` | API base URL for this run. |
| `--idempotency-key KEY` | Send `Idempotency-Key` so a retried write is applied once. |
| `BERTH_CONFIG` | Config file path. Default `~/.config/berth/config.json`. |
| `BERTH_API` | API base URL. |
| `BERTH_TOKEN` | Credential to use instead of the saved account key. |
| `BERTH_APP` | Default app, instead of `--app`. |

Exit codes: 0 success, 1 API or network error (the API's message is printed on stderr), 2 usage error.

When a command targets an app, `berth` uses the secret key saved for that app, and falls back to your account key.
Set a default app with `berth use APP` and leave out `--app`.

## Commands

### Account and session

```
berth signup [--email E] [--code C]          # emails a 6 digit code, then logs in and saves an account key
berth login [--email E] [--code C]           # email code login
berth login --token T                        # save an existing key or admin token (--token - or a pipe reads stdin)
berth logout [--all]
berth whoami
berth status
berth account show
berth account delete --confirm EMAIL
berth account keys list | create NAME | revoke KEY_ID
berth admin accounts list | show ID | update ID [--limit apps=10] [--disable|--enable] | delete ID --yes
berth admin codes --email E [--app A]
```

### Apps and keys

```
berth apps list
berth apps create NAME                       # prints the secret and publishable keys once, saves them
berth apps show NAME
berth apps usage NAME
berth apps config NAME --cors ORIGIN [--cors ORIGIN...]
berth apps export NAME [-o FILE]             # pg_dump custom format, default NAME.dump
berth apps restore NAME FILE                 # creates a new app from a dump
berth apps delete NAME --yes
berth use APP | berth use --clear
berth keys list --app A
berth keys create --app A --type publishable|secret [--name N]
berth keys revoke --app A KEY_ID
```

### Tables, columns, indexes

Column types: `text integer bigint numeric double boolean date timestamptz uuid jsonb text[] integer[]`.
Every table gets `id uuid` and `created_at`. Policies: read `secret|public|authenticated|owner`, write `secret|authenticated|owner`.

```
berth tables list --app A
berth tables create --app A NAME col:type[:notnull][:unique]... [--read R] [--write W] [--no-timestamps] [--updated-at]
berth tables show --app A T
berth tables rename --app A OLD NEW
berth tables drop --app A T --yes
berth tables policy --app A T [--read R] [--write W]
berth columns add --app A T name:type [--default V] [--not-null] [--unique] [--references TABLE[.COL]] [--on-delete cascade|restrict|set-null]
berth columns rename --app A T OLD NEW
berth columns alter --app A T COL [--type T] [--default V] [--drop-default] [--not-null|--nullable]
berth columns drop --app A T COL --yes
berth indexes list --app A T
berth indexes create --app A T COL [COL...] [--unique] [--name N]
berth indexes drop --app A T NAME
```

### Rows

Filters are `--where col.op=value`. Ops: `eq neq gt gte lt lte like ilike in is cs`, and `not.OP`.
Examples: `age.gt=30`, `name.ilike=*ann*`, `id.in=a,b,c`, `due.is=null`, `status.not.eq=done`, `tags.cs=["x"]`.

```
berth rows list --app A T [--where F]... [--select a,b] [--order col.desc] [--limit N] [--offset N] [--cursor C] [--count] [--all]
berth rows add --app A T col=value...        # values are converted by column type; null means SQL null
berth rows add --app A T --data '{"title":"a"}' | --data '[...]' | --file rows.json
berth rows upsert --app A T --on-conflict COL col=value... (or --data)
berth rows get --app A T ID
berth rows update --app A T ID col=value...
berth rows update --app A T --where F col=value...
berth rows rm --app A T ID
berth rows delete --app A T --where F --yes
berth import --app A T FILE                  # .csv (header row) or .ndjson/.jsonl, streamed, all or nothing
berth watch --app A T [--events insert,update,delete]   # live changes, one line per event, Ctrl-C to stop
```

### End-user auth

```
berth auth users list --app A
berth auth users create --app A EMAIL [--password P] [--data JSON]
berth auth users show --app A ID
berth auth users update --app A ID [--password P] [--data JSON]
berth auth users ban --app A ID [--unban]
berth auth users delete --app A ID --yes
berth auth signup --app A --email E --password P [--key PUBLISHABLE]   # prints session tokens
berth auth login  --app A --email E --password P [--key PUBLISHABLE]
berth auth code | verify | refresh | me | logout --app A ...           # the rest of the end-user flow
```

### Storage

```
berth storage buckets list --app A
berth storage buckets create --app A NAME [--read R] [--write W] [--max-file-size BYTES] [--allowed-type image/*]
berth storage buckets show | update | delete --app A NAME [--force]
berth storage ls --app A BUCKET [--prefix P]
berth storage upload --app A BUCKET FILE [KEY] [--content-type T]
berth storage download --app A BUCKET KEY [-o FILE]
berth storage rm --app A BUCKET KEY
berth storage sign --app A BUCKET KEY [--expires 3600]
```

### Functions and env vars

```
berth functions list --app A
berth functions deploy --app A NAME FILE [--verify key|user|none] [--timeout-ms N] [--memory-mb N] [--schedule CRON | --no-schedule]
berth functions show --app A NAME [--source]
berth functions logs --app A NAME [--limit N]
berth functions invoke --app A NAME [--data JSON] [--method POST] [--path-query 'a=b']
berth functions delete --app A NAME
berth env list --app A
berth env set --app A NAME=VALUE [NAME=VALUE...]   # NAME alone prompts, so the value stays out of shell history
berth env unset --app A NAME
```

A function is one file: `export default async (req) => new Response("hi")`. Imports from `npm:`, `jsr:` and `https://` work. `--schedule "*/15 * * * *"` also runs it on a cron schedule (UTC); redeploys keep the schedule until `--no-schedule`.

### Webhooks

```
berth webhooks list --app A
berth webhooks add --app A URL [--table T] [--events insert,update,delete] [--description D]   # secret shown once
berth webhooks show | remove | deliveries | test --app A ID
berth webhooks update --app A ID [--url U] [--events E] [--enable|--disable]
```

### SQL, logs, anything else

```
berth sql --app A "QUERY" [--param V]... [--read-only] [--timeout-ms N]
berth sql --app A -f FILE
berth rpc --app A FUNCTION [name=value]... [--data JSON]   # call a Postgres function made with berth sql
berth logs --app A [--limit N] [--status 4xx]
berth api METHOD PATH [--data JSON] [--app A]   # raw call, prints JSON
berth completion bash|zsh                       # eval "$(berth completion zsh)"
```

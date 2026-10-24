# Nix system configurations

This repository defines reproducible workstation and user configuration with
Nix flakes, nix-darwin, and Home Manager.

## Supported hosts

- `gaia`: Apple Silicon macOS managed by nix-darwin.

## Requirements

- GNU Make
- Upstream Nix 2.35 or newer with flakes enabled per command when needed
- Git

## Repository layout

```text
flake.nix
hosts/
  gaia/       # Apple Silicon workstation
modules/
  workstation/{common,darwin}
tests/
  pyproject.toml  # Python metadata and Ruff settings
  .mise.toml      # Optional local Python runtime
  unit/          # Source, documentation, and test-helper checks
  smoke/         # Flake metadata, checks, and output discovery
  integration/   # Real shared and per-host Nix evaluations
  fixtures/      # Nix fixture expressions and test repositories
  support.py     # Shared Nix subprocess and JSON helpers
```

The shared workstation Home Manager profile includes portable shell, Git,
Emacs, Vim, tmux, mise, and `gh` configuration.

## Bootstrap

Install upstream Nix using the official installer in an interactive Terminal,
open a fresh login shell, clone this repository, and verify:

```sh
nix --version
nix --extra-experimental-features 'nix-command flakes' flake metadata
```

Do not run an activation during bootstrap. Inventory existing files in the home
directory before the first Home Manager activation.

## Update

Update the locked inputs deliberately and review the resulting diff:

```sh
make update
```

Update only Codex from its `nixos-unstable` package source:

```sh
make update-unstable
```

## Check

Run formatting, static checks, Python unittest suites, and all host evaluations:

```sh
make check
```

Run all tests or a category:

```sh
make test
make test-unit
make test-smoke
make test-integration
```

Tests use Python's standard-library `unittest` runner, with no third-party test
dependencies. The Nix development shell provides Python 3.14 and Ruff. Unit
tests inspect files and test helpers without invoking Nix; smoke and integration
tests require Nix and access to the locked inputs. Failed evaluations report the
command, exit status, stdout, and stderr.

For direct discovery with Python 3.14 or newer from the repository root:

```sh
python3 -m unittest discover -s tests -t . -v
python3 -m unittest tests.integration.test_gaia -v
```

From `tests/`, optional mise tooling uses the existing approved Python version:

```sh
cd tests
mise install
mise exec -- python -m unittest discover -s . -t .. -v
```

Mise is optional; `make` and CI use Nix without downloading mise runtimes.

Format Nix and Python with the flake formatter and Ruff:

```sh
make format
```

Checks never activate a system or mutate Homebrew. CI runs lint, tests, Gaia
evaluation, and the Gaia build on macOS.

## Build

Build without switching the active generation:

```sh
make build
```

## Activate

Gaia activation is explicit and requires macOS administrator approval:

```sh
make bootstrap   # first activation only
make switch      # subsequent activations
```

`bootstrap` installs nix-darwin through `nix run`; use `switch` after
the first successful activation.

## Rollback

Use the native system manager rollback and generation selection tools. Review
the generation before activating a rollback; this repository does not automate
reboot or rollback activation.

## Secrets

Keep tokens, SSH private keys, credentials, decrypted values, and private keys
outside this repository and outside the Nix store.

## Codex and MCP connections

Codex comes from the locked `nixpkgs-unstable` input. Home Manager's native
`programs.codex.mutableSettings = true` merges declared settings into a writable
`~/.codex/config.toml` during explicit activation. Existing settings remain unless
overridden by a Nix declaration. `programs.codex.enableMcpIntegration = true`
imports the shared `programs.mcp.servers` registry. Edit
`modules/workstation/common/home/mcp.nix` to change global MCP connections and
`codex.nix` for Codex preferences.

Nix declares `gpt-5.6-terra` as the default model, `medium` reasoning effort,
`pragmatic` personality, and `features.js_repl = false`. Other existing settings
remain mutable and are preserved by Home Manager's merge.

| Context | n8n endpoint |
| --- | --- |
| Default | `https://n8n.tjmaynes.com/mcp-server/http` |
| `~/workspace/notebook/development/consulting/sproutup` | `https://sproutupdigital.n8n.io/mcp-server/http` |

Sproutup owns its native `.codex/config.toml` independently of this repository:

```toml
[mcp_servers.n8n]
url = "https://sproutupdigital.n8n.io/mcp-server/http"
```

Add this block alongside existing project settings. Codex layers it over the
global configuration, preserving other inherited MCP connections. Codex must
trust the project to load it. Start a new task there to select the override;
`cd` within an existing task does not switch its MCP connection. Home Manager
does not create, update, or require the Sproutup folder, and no named profile or
project activation script is needed.

After you explicitly choose to activate with `make switch`, complete OAuth from
the corresponding directory. Run these commands yourself, selecting the matching
n8n account in the browser:

```sh
cd ~/workspace/config
codex mcp login n8n
codex mcp list

cd ~/workspace/notebook/development/consulting/sproutup
codex mcp login n8n
codex mcp list
```

Activation does not log in, contact n8n, or change project trust. Keep credentials
in Codex's local credential storage; never declare token values or secret headers
in Nix. The two hostnames have not been connection-tested by repository checks.

The upstream merger preserves settings rather than TOML comments or formatting.
Removing a declaration stops enforcing its value; remove obsolete keys from the
writable file yourself. New files use mode `0600`. Close Codex during activation
to avoid concurrent writes. Validation and builds do not modify live Codex files.

This option requires newer Home Manager than `release-26.05`, so its input now
tracks `master`, pinned in `flake.lock`. Nixpkgs and nix-darwin remain on 26.05.
Home Manager currently reports the resulting 26.11/26.05 version mismatch; the
warning is retained rather than suppressed.

## Read-only iCloud Mail

Gaia includes a read-only iCloud Mail mirror for `tj@tjmaynes.com`.
OfflineIMAP stores the local Maildir at `$HOME/workspace/mailbox`; it never
modifies the remote iCloud mailbox. Mutt opens that local Maildir read-only and
has sending disabled.

Notmuch is also available alongside Mutt, with its Emacs interface. It indexes
the same local Maildir and stores tags separately; Maildir flag synchronization
is disabled. No sending transport is configured for Notmuch.

After activation, generate an iCloud app-specific password in your Apple
Account, then store it locally on Gaia. Do not use or store the Apple
Account password:

```sh
pass insert mail/icloud/tj@tjmaynes.com
```

If the local password store has not yet been initialized, initialize it first
with the appropriate GPG recipient using `pass init`. Sync mail manually, then
open it in Mutt:

```sh
sync-icloud-mail
mutt
```

`sync-icloud-mail` runs `notmuch new` after OfflineIMAP succeeds, keeping the
search index current. If syncing fails, indexing is skipped. Search the mirror:

```sh
sync-icloud-mail
notmuch search 'tag:inbox'
```

In Emacs, run `M-x notmuch` to browse and search the index. Run `notmuch new`
to reindex without syncing. Notmuch initially tags newly indexed messages as
`inbox` and `unread`, independently of their iCloud folder or flags.

After `make switch`, Gaia's Home Manager launch agent runs `sync-icloud-mail`
every night at 2:00 a.m. in the Mac's local timezone while you are logged in.
If the Mac is asleep then, launchd runs it on wake. Activation itself does not
sync or index mail. Manual syncing remains available.

The job needs `pass` to decrypt the stored app-specific password without an
interactive GPG prompt. Run a manual sync first to verify credentials; if GPG
needs unlocking later, the scheduled sync may fail. Logs are stored in
`$HOME/workspace/mailbox/logs/stdout.log` and `stderr.log`. Inspect the agent with:

```sh
launchctl print gui/$(id -u)/org.nix-community.home.sync-icloud-mail
```

## Syncthing

Syncthing runs as your user in the background. On Gaia, Home Manager manages
the macOS launch agent `org.nix-community.home.syncthing`, which starts at
login and restarts after a failure. It does not open a browser automatically.

After explicitly activating the configuration with `make switch`, open
[the local Syncthing web interface](http://127.0.0.1:8384) to add devices and
choose folders to sync. The web interface listens only on loopback; devices
and folders configured there persist across rebuilds. No peers or sync paths
are declared by this repository.

Syncthing keeps its configuration, database, and generated identity keys in
`~/Library/Application Support/Syncthing` on Gaia. Keep identity keys and API
credentials outside the repository and Nix store. Logs are written to
`~/Library/Logs/Syncthing/syncthing-stdout.log` and
`~/Library/Logs/Syncthing/syncthing-stderr.log`.

Inspect the user agent after activation:

```sh
launchctl print "gui/$(id -u)/org.nix-community.home.syncthing"
```

Validation does not start Syncthing or activate the configuration.

## Mise

Home Manager declares the approved mise tool versions. After an explicit
activation, install runtimes manually:

```sh
mise install
```

Runtime downloads are never performed by activation hooks or CI.

## Applications

Gaia installs its nixpkgs graphical application bundles in `/Applications/Nix Apps`
during activation. Other applications, including Google Chrome (the
`google-chrome` cask) and Zen Browser (the `zen` cask), use its declarative
Homebrew configuration.

Gaia does not change its default browser automatically.

Atuin is installed through the Homebrew `atuin` formula. Gaia's Zsh integration
uses `/opt/homebrew/bin/atuin` so its history database is opened by the Homebrew
version. Update it with `brew upgrade atuin`; Homebrew upgrades are disabled
during Nix activation.

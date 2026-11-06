# Nix system configurations

This repository defines reproducible workstation and user configuration with
Nix flakes, nix-darwin, and Home Manager.

## Supported hosts

- `gaia`: Apple Silicon macOS managed by nix-darwin.
- `athena`: headless x86_64 NixOS development server.
  Hardware and access credentials must be completed during installation.

## Requirements

- GNU Make
- Upstream Nix 2.35 or newer with flakes enabled per command when needed
- Git

## Repository layout

```text
flake.nix
hosts/
  gaia/       # Apple Silicon workstation
  athena/     # Headless Linux development server and hardware template
modules/
  common/     # Portable workstation and Home Manager modules; config.nix shares system settings
  darwin/     # macOS-only system and Home Manager modules
  nixos/      # NixOS system services and headless Home Manager composition
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

Update Home Manager's pre-release Codex support without changing nixpkgs or
nix-darwin:

```sh
make update-home-manager
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

Checks never activate a system or mutate Homebrew. CI runs lint, tests, both
host evaluations, and the Gaia build on macOS. A separate Ubuntu job runs
formatting checks, lint, tests, Athena evaluation, and `make build-athena`.
Boot and hardware checks still require the actual machine.

## Build

Build without switching the active generation:

```sh
make build
```

`make build` (or `make build-gaia`) builds Gaia. Build Athena on x86_64 Linux
or using a configured Linux remote builder:

```sh
make eval-athena     # evaluation only; also works on Gaia
make build-athena    # Linux build; does not activate
```

`make eval` evaluates both hosts; `make eval-gaia` evaluates Gaia alone.

## Activate

Gaia activation is explicit and requires macOS administrator approval:

```sh
make bootstrap   # first activation only
make deploy      # subsequent activations
```

`bootstrap` installs nix-darwin through `nix run`; use `deploy` after
the first successful activation. Home Manager reports each managed agent skill
that is installed or updated during activation.

Athena installation and activation are separate, explicitly approved actions;
`make bootstrap` and `make deploy` continue to target Gaia only.

## Athena preparation and access

Athena runs SSH, Tailscale, code-server, a persistent Codex app-server, and a
headless Orca runtime. Gaia installs the Orca desktop application.
Both development services run as `tjmaynes` and share `/home/tjmaynes/workspace`.
The headless profile reuses shell, Git, Vim, terminal Emacs, tmux, mise, Codex,
MCP, and skills without installing Gaia's graphical editors or mail configuration. Install
project runtimes using `mise install` or project Nix shells after provisioning.
Emacs settings live in `modules/common/home/emacs.nix` for both hosts; Athena
selects `emacs-nox`, while Gaia retains its default Emacs package.

### Installation prerequisites

`hosts/athena/hardware.nix` is a **template**, not detected host hardware.
It describes an ext4 root labeled `nixos` and a FAT EFI partition labeled
`BOOT`. Before installation, boot the NixOS installer in UEFI mode, choose and
mount the intended filesystems, and replace this file with hardware generated
for those mounts:

```sh
nixos-generate-config --root /mnt --show-hardware-config > hosts/athena/hardware.nix
```

This command only generates configuration; partitioning/mounting and
`nixos-install --flake .#athena` remain manual installation steps. Review the
generated file, including any swap configuration, and stage it so flakes see
it. Bootloader settings live separately in `hosts/athena/default.nix`.

Add your SSH **public** key to `users.users.tjmaynes.openssh.authorizedKeys.keys`
in `modules/nixos/default.nix`. Set a local password with `passwd tjmaynes`
from an administrative console so `sudo` is usable. Password SSH and root SSH
are disabled. No initial password or private key is declared by Nix.

Prepare a fresh Tailscale enrollment key in SOPS-encrypted
`secrets/athena.sops.yaml` using the [provisioning guide](secrets/README.md).
Encrypt it for Athena's persistent SSH host key and optionally an operator
age recipient. The upstream autoconnect service waits for SOPS decryption and
reads the root-only key from `/run/secrets/tailscale-auth-key` at boot.
The actual encrypted file is not created by this preparation work: until it
exists in the flake source, evaluation emits an explicit warning and automatic
enrollment stays disabled. Keep console access for initial provisioning.
Approve the node and its tailnet ACLs as required by the new key's policy.
Initial enrollment and subsequent boots use `--accept-dns=false` and
`--netfilter-mode=nodivert`. Nix reapplies these preferences using
`tailscale set`; `nodivert` prevents Tailscale's default accept-all rule from
bypassing NixOS's port filtering.
Athena opens TCP 22, 6768, and 8080 only on `tailscale0`; LAN SSH is not opened.
Keep console access until `ssh tjmaynes@<athena-tailscale-ip>` works.
DNS acceptance is disabled to avoid assuming Gaia's home DNS setup during
enrollment; configuring split DNS for other home services is separate.

### Browser development through Caddy

The intended URL is `https://coding.bewoogie.local`. The existing home-server
Caddy instance terminates TLS; Athena serves HTTP on port 8080 over Tailscale.
code-server retains password authentication. On Athena, create the runtime
environment file locally before starting code-server:

```sh
sudo install -d -m 0700 /var/lib/athena
sudo install -m 0600 /dev/null /var/lib/athena/code-server.env
sudoedit /var/lib/athena/code-server.env
```

Put `PASSWORD=<a-unique-password>` in that root-owned file. It is required by
the unit and is never generated by Nix. code-server intentionally fails to
start while the file is missing; after creating it, run
`sudo systemctl restart code-server`. On an existing installation, edit the
file instead of recreating it with `install`, which would empty it.

The separate home-server configuration does **not yet contain this route**.
Add its DNS/proxy entry there, pointing `coding.bewoogie.local` at the home
server and proxying to Athena's stable Tailscale IPv4 address on port 8080.
The resulting Caddy route should be equivalent to:

```caddyfile
coding.bewoogie.local {
    tls internal
    reverse_proxy http://<athena-tailscale-ip>:8080
}
```

Use the home-server repository's route registry rather than duplicating its
generated Caddy configuration. Preserve its internal CA; browsers must trust
that CA. Caddy supports WebSocket upgrades through `reverse_proxy`. Tailnet
ACLs must permit the home server to reach Athena:8080; limit access to that
backend to the proxy and administrators. This repository does not change
home-server routes, DNS, certificates, or tailnet ACLs.

### Shared editor extensions and settings

`modules/common/vscode.nix` owns the pinned extension list and editor settings
for Darwin VS Code and Athena's code-server. Both consumers use their own
platform's packages and home paths. Add shared extensions there once.

Darwin retains Pylance and Microsoft's Dev Containers extension. code-server
omits those desktop-only extensions and uses the open-source Pyright extension
for Python language support instead. Other extensions use the same pinned
versions on both platforms. Runtime compatibility still needs confirmation
when Athena is installed.

The upstream NixOS `services.code-server.package` option supports
`pkgs.vscode-with-extensions` with `vscode = pkgs.code-server`; this repository
uses that integration rather than an extension-installation script. The bundle
uses an immutable extension directory, so manage its extensions through Nix.
Home Manager's pinned/current VS Code module writes desktop-specific paths;
it has no code-server profile. Shared settings are therefore written using
`xdg.dataFile` to `code-server/User/settings.json` under the user's data home.
That file is declaratively managed; edit the shared Nix settings instead of
editing it through the browser. Existing files may need moving aside before
the first explicit activation; preserve any user settings you want to merge.

code-server uses Open VSX for additional extension discovery; it cannot use
the Microsoft Marketplace directly. See the
[code-server extension FAQ](https://coder.com/docs/code-server/FAQ#why-cant-code-server-use-microsofts-extension-marketplace)
and [Pyright](https://github.com/microsoft/pyright).

### Persistent Codex

`codex.service` starts at boot after Home Manager activation, without an
interactive login. It restarts on failure and keeps auth/history/configuration
in `/home/tjmaynes/.codex`. Authentication uses local files rather than a
desktop keyring. Sign in once as `tjmaynes` on Athena with `codex login`
(use `codex login --device-auth` when available for a headless sign-in).
Never put the login state or API keys in the repository or Nix store.

Connect from an SSH session or the code-server terminal:

```sh
codex --remote unix:///run/codex/app-server.sock
```

The socket lives in a private directory owned by `tjmaynes`; no Codex TCP
port is opened. A plain `codex` command starts its normal CLI workflow;
use `--remote` to connect to this persistent instance. The desktop app's SSH
integration may launch its own server; it does not automatically attach to
this systemd socket. This configuration does not enable mobile pairing.

Home Manager's pinned Codex module and current upstream options manage the
package, settings, MCP and skills, but provide no persistent service option.
`modules/nixos/development.nix` supplies only that missing systemd lifecycle,
using the same locked Codex package as the CLI. No input update is needed.
See the [upstream options](https://nix-community.github.io/home-manager/options/home-manager/programs/codex.html)
and [Codex app-server documentation](https://learn.chatgpt.com/docs/app-server).

After login, restart Codex if needed with `sudo systemctl restart codex`.

### Orca remote runtime

The pinned `llm-agents.nix` package installs Orca on both hosts. Athena's
`orca.service` starts the headless runtime as `tjmaynes` at boot and advertises
`athena:6768`; Gaia must be able to resolve `athena` over Tailscale (MagicDNS).
The port is only opened on the Tailscale interface. After activating Athena's
configuration, retrieve the pairing URL on Athena:

```sh
sudo journalctl -u orca -b
```

In Orca on Gaia, open Settings → Remote Orca Servers → Add Server and paste
the URL. The pairing URL grants access to the runtime; keep it private. If
MagicDNS is unavailable, use Athena's Tailscale IP in the URL or configure a
reachable tailnet hostname. Authenticate provider CLIs on Athena separately;
the desktop's credentials do not transfer. For a managed Codex account, run
`orca account add --agent codex` on Athena as `tjmaynes`. See the
[Orca remote server guide](https://github.com/stablyai/orca/blob/main/docs/site/content/docs/remote-servers.mdx).
Inspect boot services and logs:

```sh
systemctl status codex code-server tailscaled sshd
journalctl -u codex -u code-server -b
```

Before treating Athena as ready, reboot it, verify both services start without
a user login, connect to the Codex socket, open the browser URL, and run a real
project build/test. Check that TCP 8080 is unreachable through the LAN address.
Also verify a temporary listener on another port (for example 9000) is
unreachable from a tailnet peer. Those acceptance checks cannot be performed
by macOS evaluation tests.

## Rollback

Use the native system manager rollback and generation selection tools. Review
the generation before activating a rollback; this repository does not automate
reboot or rollback activation.

## Secrets

Keep tokens, SSH private keys, credentials, decrypted values, and private keys
outside this repository and outside the Nix store.

SOPS-encrypted ciphertext is allowed under `secrets/`. Athena uses the locked
`sops-nix` NixOS module and its Ed25519 SSH host key for decryption. The
development shell includes `sops`, `age`, and `ssh-to-age`. Follow
[secrets/README.md](secrets/README.md) to add Athena's new Tailscale auth key;
never commit a decrypted file or a private decryption key. The code-server
password and Codex authentication retain their existing runtime-file setup.

Use `make sops-edit` to edit the encrypted file or `make sops-view` to print its
decrypted contents locally. Both default to `secrets/athena.sops.yaml`; override
the path with `SOPS_FILE=secrets/another.sops.yaml`.

## Codex and MCP connections

Codex comes from the locked `llm-agents.nix` input, while Home
Manager tracks its pre-release 26.11 development line for native Codex support.
Nixpkgs and nix-darwin remain pinned to their 26.05 release branches. Home Manager may emit
a version-mismatch warning for this deliberate boundary; do not suppress it.

Home Manager merges the declared Codex settings into the writable
`~/.codex/config.toml` only during explicit activation. It preserves other
setting values, but may normalize comments and formatting. The shared MCP
registry supplies n8n at `https://n8n.tjmaynes.com/mcp-server/http` and the
local [Playwright MCP server](https://github.com/microsoft/playwright-mcp) for
browser automation. Playwright MCP uses the version pinned by Nixpkgs.

This repository does not manage Codex credentials, authentication, project
trust, or project-specific configuration. Keep those values in Codex's local
credential storage. Close Codex before an explicit activation to avoid
concurrent writes. Validation never updates live Codex files or contacts n8n.

## Codex skills

Home Manager links the following repository-managed skills into
`~/.agents/skills` during activation. Codex can select applicable skills from
their descriptions; to request one explicitly, include `$skill-name` in your
prompt. For example, ask `$last30days research recent Nix developments` or
`$grill-me review this plan`. Some workflow skills are intended to be invoked
automatically when their conditions apply. The list reflects the sources pinned
in `flake.lock`; it excludes Codex built-in skills and separately installed
plugins.

| Skill | Purpose and usage | Source |
| --- | --- | --- |
| `agent-context-generator` | Generate an `AGENTS.md` guide for a repository. | [tjmaynes/skills](https://github.com/tjmaynes/skills) |
| `resume-generator` | Assess a job fit and create a tailored RenderCV resume from career history. | [tjmaynes/skills](https://github.com/tjmaynes/skills) |
| `superblog` | Draft a blog post and accompanying social media copy. | [tjmaynes/skills](https://github.com/tjmaynes/skills) |
| `grill-me` | Explicitly request a rigorous interview about a plan or design. | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `grilling` | Stress-test a plan or idea through questions. | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `interview-me` | Clarify an underspecified request one question at a time. | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) |
| `humanizer` | Rewrite prose to remove common AI writing patterns; invoke with `$humanizer`. | [blader/humanizer](https://github.com/blader/humanizer) |
| `last30days` | Research recent discussion and developments on a topic; provide the topic in your prompt. | [mvanhorn/last30days-skill](https://github.com/mvanhorn/last30days-skill) |
| `archify` | Create interactive HTML diagrams and explainers; describe the system or topic to visualize. | [tt-a1i/archify](https://github.com/tt-a1i/archify) |
| `brainstorming` | Explore requirements and design before creative work. | [obra/superpowers](https://github.com/obra/superpowers) |
| `diagnosing-superpowers` | Investigate a problematic Superpowers session or prepare a bug report. | [obra/superpowers](https://github.com/obra/superpowers) |
| `dispatching-parallel-agents` | Coordinate independent tasks using multiple agents when delegation is allowed. | [obra/superpowers](https://github.com/obra/superpowers) |
| `executing-plans` | Execute an implementation plan in the current session. | [obra/superpowers](https://github.com/obra/superpowers) |
| `finishing-a-development-branch` | Decide how to integrate a completed, tested branch. | [obra/superpowers](https://github.com/obra/superpowers) |
| `receiving-code-review` | Evaluate and address review feedback. | [obra/superpowers](https://github.com/obra/superpowers) |
| `requesting-code-review` | Request a review of completed implementation work. | [obra/superpowers](https://github.com/obra/superpowers) |
| `subagent-driven-development` | Execute independent implementation tasks with subagents when delegation is allowed. | [obra/superpowers](https://github.com/obra/superpowers) |
| `systematic-debugging` | Investigate bugs and test failures before fixing them. | [obra/superpowers](https://github.com/obra/superpowers) |
| `test-driven-development` | Develop features and fixes using a failing test first. | [obra/superpowers](https://github.com/obra/superpowers) |
| `using-git-worktrees` | Set up an isolated worktree for development when needed. | [obra/superpowers](https://github.com/obra/superpowers) |
| `using-superpowers` | Identify applicable skills at the start of a conversation. | [obra/superpowers](https://github.com/obra/superpowers) |
| `verification-before-completion` | Verify results before reporting work complete. | [obra/superpowers](https://github.com/obra/superpowers) |
| `writing-plans` | Write an implementation plan from requirements or a specification. | [obra/superpowers](https://github.com/obra/superpowers) |
| `writing-skills` | Create, edit, or verify skills. | [obra/superpowers](https://github.com/obra/superpowers) |

## Read-only iCloud Mail

Darwin-only mail configuration and its scheduled sync live in
`modules/darwin/mail.nix`; they are imported by the Darwin home profile.

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

After `make deploy`, Gaia's Home Manager launch agent runs `sync-icloud-mail`
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

Darwin-only Syncthing configuration lives in `modules/darwin/syncthing.nix`.

Syncthing runs as your user in the background. On Gaia, Home Manager manages
the macOS launch agent `org.nix-community.home.syncthing`, which starts at
login and restarts after a failure. It does not open a browser automatically.

After explicitly activating the configuration with `make deploy`, open
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

Gaia includes `/opt/homebrew/bin` and `/opt/homebrew/sbin` in its system PATH,
after the Nix profile paths, so Homebrew commands are available in both login
and non-login shells. If an existing terminal cannot find `atuin`, restore it
for that session with `export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"`.

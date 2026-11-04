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
  common/     # Portable workstation and Home Manager modules
  darwin/     # macOS-only system and Home Manager modules
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
make deploy      # subsequent activations
```

`bootstrap` installs nix-darwin through `nix run`; use `deploy` after
the first successful activation.

## Rollback

Use the native system manager rollback and generation selection tools. Review
the generation before activating a rollback; this repository does not automate
reboot or rollback activation.

## Secrets

Keep tokens, SSH private keys, credentials, decrypted values, and private keys
outside this repository and outside the Nix store.

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

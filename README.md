# Nix system configurations

This repository defines reproducible workstation and user configuration with
Nix flakes, nix-darwin, and Home Manager.

## Supported host

`gaia` is an Apple Silicon macOS workstation managed by nix-darwin.

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
  common/     # Portable workstation and Home Manager modules; config.nix shares system settings
  darwin/     # macOS-only system and Home Manager modules
tests/
  pyproject.toml  # Python metadata and Ruff settings
  .mise.toml      # Optional local Python runtime
  unit/          # Source, documentation, and test-helper checks
  smoke/         # Flake metadata, checks, and output discovery
  integration/   # Nix evaluations for Gaia and module fixtures
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

Run formatting, static checks, Python unittest suites, and Gaia's system evaluation:

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

Checks never activate Gaia or mutate Homebrew. GitHub Actions runs formatting
checks, lint, tests, and the Gaia evaluation and build on macOS.

## Build

Build without switching the active generation:

```sh
make build
```

`make build` and `make build-gaia` both build Gaia. Use `make eval` or
`make eval-gaia` to evaluate its system derivation without building.

## Activate

Gaia activation is explicit and requires macOS administrator approval:

```sh
make bootstrap   # first activation only
make deploy      # subsequent activations
```

`bootstrap` installs nix-darwin through `nix run`; use `deploy` after
the first successful activation. Home Manager reports each managed agent skill
that is installed or updated during activation.

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
registry supplies the local [Playwright MCP server](https://github.com/microsoft/playwright-mcp) for
browser automation. Playwright MCP uses the version pinned by Nixpkgs.

Home Manager also links the global Codex instructions from
[`modules/common/home/files/context.md`](modules/common/home/files/context.md)
to `~/.codex/AGENTS.md` on Gaia. Edit the repository file to update
them. A pre-existing unmanaged file at that destination can block activation;
review and move it aside before activating. A `~/.codex/AGENTS.override.md`
file takes precedence over these instructions.

This repository does not manage Codex credentials, authentication, project
trust, or project-specific configuration. Keep those values in Codex's local
credential storage. Close Codex before an explicit activation to avoid
concurrent writes. Validation never updates live Codex files.

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
`google-chrome` cask), use its declarative Homebrew configuration.

Home Manager opens ChatGPT at graphical login through the
`org.nix-community.home.open-chatgpt` LaunchAgent. The first activation can
also open ChatGPT when it loads the agent.

Gaia does not change its default browser automatically.

Atuin is installed through the Homebrew `atuin` formula. Gaia's Zsh integration
uses `/opt/homebrew/bin/atuin` so its history database is opened by the Homebrew
version. Update it with `brew upgrade atuin`; Homebrew upgrades are disabled
during Nix activation.

Gaia includes `/opt/homebrew/bin` and `/opt/homebrew/sbin` in its system PATH,
after the Nix profile paths, so Homebrew commands are available in both login
and non-login shells. If an existing terminal cannot find `atuin`, restore it
for that session with `export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"`.

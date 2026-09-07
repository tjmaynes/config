# Nix Configuration Modernization Design

**Status:** Approved for implementation planning  
**Date:** 2026-08-28

## Summary

Modernize this channel-based 2022 Nix configuration into one explicit, stable-by-default flake for two hosts:

- `gaia`: Apple Silicon macOS, managed by nix-darwin with embedded Home Manager.
- `athena`: x86_64 NixOS, managed by NixOS with embedded Home Manager.

The modernization will pin compatible Nixpkgs, Home Manager, and nix-darwin releases; consolidate active user configuration from the external dotfiles repository; make Home Manager responsible for portable developer tooling; and make both hosts evaluable without access to the physical machines.

`apollo` and `demeter` are retired and will be removed. `kratos` is not a supported host output and its stale installer entry points will also be removed.

## Goals

- Replace mutable channels and `NIX_PATH` imports with locked flake inputs.
- Produce `darwinConfigurations.gaia` and `nixosConfigurations.athena` from a clean checkout.
- Align on the current stable 26.05 release family:
  - `github:NixOS/nixpkgs/nixos-26.05`
  - `github:nix-community/home-manager/release-26.05`
  - `github:nix-darwin/nix-darwin/nix-darwin-26.05`
- Make Home Manager the owner of portable CLI packages and active user configuration.
- Use the current `tmp/config/vars` inventory as the source of truth for Gaia applications and Git identity/settings.
- Preserve Athena's workstation intent while translating removed options and obsolete versioned packages.
- Evaluate both hosts locally and in CI without activation.
- Document a conventional upstream Nix bootstrap for Gaia.

## Non-goals

- Managing secrets, GitHub tokens, private SSH keys, or service credentials.
- Generating SSH private keys.
- Activating either host as part of automated checks.
- Pretending to validate Athena hardware without the physical machine.
- Migrating to Lix, adding an unstable package input, or introducing a flake framework.
- Increasing NixOS, nix-darwin, or Home Manager state versions merely because dependencies are newer.
- Preserving Apollo, Demeter, channel compatibility, Stow, or the external dotfiles runtime dependency.

## Research basis

- Nix flakes provide standard inputs and outputs and a `flake.lock` that pins dependencies. Flakes still require the experimental `nix-command` and `flakes` features: <https://nix.dev/concepts/flakes.html>.
- NixOS 26.05 is the current stable release as of this design and receives updates through 2026-12-31: <https://nixos.org/blog/announcements/2026/nixos-2605/>.
- Home Manager publishes release branches aligned with NixOS releases to avoid Nixpkgs incompatibilities: <https://github.com/nix-community/home-manager>.
- nix-darwin supports and recommends flake-based configuration and publishes a 26.05 branch: <https://github.com/nix-darwin/nix-darwin/blob/master/README.md>.
- The official upstream Nix macOS bootstrap is the multi-user installer documented at <https://nixos.org/download/>.

## Source-of-truth precedence

When existing sources disagree, implementation must apply this precedence:

1. Decisions in this approved specification.
2. `tmp/config/vars/common.yml`, `git.yml`, and `macos.yml` for current Gaia identity, Git settings, and application inventory.
3. Active, non-secret behavior from `/Users/tjmaynes/workspace/code/tjmaynes/dotfiles` for shell, tmux, Vim, and mise configuration.
4. Existing files in this repository for Athena behavior and macOS preferences not superseded above.

This precedence specifically resolves the shell-framework conflict in favor of the newer Oh My Zsh configuration rather than the legacy Prezto configuration.

## Dependency architecture

`flake.nix` will remain a small composition root. It declares the three aligned stable inputs, makes Home Manager and nix-darwin follow the top-level Nixpkgs input, and creates the two host outputs. `flake.lock` records exact input revisions and is committed.

The design will use direct calls to:

- `nix-darwin.lib.darwinSystem` for Gaia.
- `nixpkgs.lib.nixosSystem` for Athena.

Small repository-local constructors may remove repeated Home Manager wiring, but they must not hide host platform, imported modules, state versions, or user identity. No `flake-parts`, flake-utils, dendritic framework, or generated module discovery is needed for two hosts.

Shared values such as username, full name, email, timezone, and workspace path will be passed explicitly through module arguments or a small plain attribute set. They will not be represented as a cross-module custom `settings` option and will not be obtained through `builtins.getEnv`.

## Repository structure

The intended module layout is platform-first:

```text
flake.nix
flake.lock
hosts/
├── gaia/
│   └── default.nix
└── athena/
    ├── default.nix
    └── hardware-eval.nix
modules/
├── common/
│   ├── nix.nix
│   └── home/
│       ├── default.nix
│       ├── git.nix
│       ├── mise.nix
│       ├── packages.nix
│       ├── shells.nix
│       ├── tmux.nix
│       └── vim.nix
├── darwin/
│   ├── default.nix
│   ├── homebrew.nix
│   ├── preferences.nix
│   └── home/
│       └── default.nix
└── nixos/
    ├── default.nix
    ├── desktop.nix
    ├── services.nix
    └── home/
        └── default.nix
```

Files may be combined when their final contents are too small to justify a separate module. The boundaries must remain visible: system modules may not be imported as Home Manager modules, and Home Manager modules may not be imported as system modules.

The import flow is:

- Gaia imports common Nix policy, Darwin system modules, common Home Manager modules, and Darwin Home Manager modules.
- Athena imports common Nix policy, NixOS system modules, common Home Manager modules, and NixOS Home Manager modules.

## Host output contracts

### Gaia

- Output name: `darwinConfigurations.gaia`.
- Platform: `aarch64-darwin`.
- System manager: nix-darwin.
- User manager: Home Manager embedded through the nix-darwin module.
- `system.stateVersion` remains `4`.
- `home.stateVersion` remains `"22.05"`.
- Home directory is explicit (`/Users/tjmaynes`) rather than derived from process environment.

### Athena

- Output name: `nixosConfigurations.athena`.
- Platform: `x86_64-linux`.
- System manager: NixOS.
- User manager: Home Manager embedded through the NixOS module.
- `system.stateVersion` remains `"22.05"`.
- `home.stateVersion` remains `"22.05"`.
- Home directory is explicit (`/home/tjmaynes`).

State-version values are compatibility contracts. Updating dependency inputs must not change them without a separate migration justified by the applicable release notes.

## Common system policy

`modules/common/nix.nix` owns settings supported by both NixOS and nix-darwin:

- Enable `nix-command` and `flakes` after initial bootstrap.
- Enable unfree packages because the approved host inventories require them.
- Keep broken packages disabled.
- Configure Nix garbage-collection and optimization only when the same semantics are supported on both platforms; platform-specific scheduling belongs in the platform module.
- Do not recreate `NIX_PATH`, channels, tarball TTL settings, or hard-coded platform overrides.

## Common Home Manager ownership

`modules/common/home` is the portable developer environment. It owns:

- User identity and explicit home paths supplied by each host.
- Portable environment variables for the workspace and code directory.
- CLI packages derived from the Gaia inventory.
- Git identity, aliases, ignores, editor, delta integration, and GPG program settings from the newer vars.
- Zsh, Oh My Zsh, shell history, aliases, completion, autosuggestions, and syntax highlighting.
- Viable non-secret shell helpers from the active dotfiles.
- Atuin with Zsh integration.
- direnv and nix-direnv.
- mise and Zsh integration.
- tmux behavior translated from `.tmux.conf`.
- Vim behavior and viable plugins translated from `.vimrc` using Home Manager/Nix packages rather than runtime downloads.

The newer Oh My Zsh setup is authoritative. It uses the `robbyrussell` theme and the applicable Git, macOS, Kubernetes, autosuggestions, completions, and syntax-highlighting plugins. Platform-inapplicable plugins must be placed in the platform home module rather than conditionally leaking platform assumptions into the common module.

`.zsh_dynamic`, `.bash_onstart.sh`, the Prezto configuration, Stow, and shell-time Git clones or downloads are removed. Bash may remain available as a system shell dependency, but this design does not preserve a second, parallel Bash customization layer.

The `workspace` alias and self-contained `kill-process-on-port`, `convert-m4a-to-mp3`, and `morning-paper` helpers remain declarative shell behavior. The obsolete `dotfiles` alias, the unprovisioned `task-master` alias, `mods`-dependent commit helpers, and the external backup-script wrapper are removed rather than retaining broken dependencies.

## Package ownership

The current Gaia formula list is translated as follows:

| Current item | New owner |
| --- | --- |
| `atuin` | Home Manager `programs.atuin` |
| `git` and `git-delta` | Home Manager Git/delta modules and packages |
| `mise` | Home Manager mise module |
| `tmux` | Home Manager tmux module |
| `zsh` | System shell plus Home Manager Zsh module |
| `codex` | Stable Nixpkgs `codex` package |
| `bat`, `curl`, `htop`, `ffmpeg`, `git-lfs`, `gpg2`, `jq`, `pandoc`, `shfmt`, `tree`, `watchman` | Home Manager packages using their Nixpkgs equivalents |
| `ssh-copy-id` | Home Manager's OpenSSH package, which supplies the utility |
| `webp` | Home Manager's Nixpkgs WebP tools package |
| `stow` | Removed; Home Manager replaces its role |
| `mas` | Darwin/Homebrew integration detail, not a portable CLI package |

The stable Nixpkgs 26.05 branch contains the OpenAI Codex package and mise, so neither requires an unstable input. Runtime language versions remain mise-managed because the current developer workflow already records them in `.tool-versions`:

- Python 3.13.10
- Node.js 24.11.1
- kubectl 1.26.2
- just 1.43.1
- Go 1.25.3
- Bun 1.3.10
- direnv 2.32.1

Home Manager will own the mise manifest or an equivalent committed mise configuration. It must not run unconditional network-dependent `mise install` during system activation. Runtime installation occurs explicitly through mise after activation.

## Darwin ownership

`modules/darwin` owns system-level macOS behavior:

- Host and computer names.
- Nix daemon and nix-darwin integration.
- Keyboard mapping.
- Finder, Dock, login-window, screenshot, global UI, firewall, and software-update preferences that remain supported by nix-darwin 26.05.
- Homebrew and Mac App Store declarations.

The current Gaia application inventory is authoritative:

- Homebrew casks: Google Chrome, Obsidian, and Tailscale.
- Mac App Store: Bitwarden (`1352778147`).

CLI formulae move to Home Manager. The obsolete `homebrew.brewPrefix`, top-level `homebrew.cleanup`, top-level `homebrew.autoUpdate`, taps, and embedded cask arguments will not be copied verbatim. They will be translated to current nix-darwin options only where needed.

The first activation must not use `zap` cleanup or automatically delete unmanaged Homebrew state. Moving duplicate formulae out of Homebrew is a separate, explicit cleanup operation performed only after the Home Manager replacements are present and verified. GUI application cleanup also remains opt-in.

`modules/darwin/home` contains only user-level macOS differences, such as the macOS-specific Oh My Zsh plugin or PATH additions that cannot be expressed through nix-darwin.

## NixOS ownership

`modules/nixos` preserves Athena's intent while updating current module interfaces:

- systemd-boot and EFI boot policy.
- NetworkManager and firewall access for k3s.
- i3 on X11 and its user session configuration.
- PipeWire-based audio in place of the removed legacy sound/PulseAudio declarations.
- VMware guest support.
- Docker and k3s server services.
- Fonts and display scaling.
- The normal user, groups, and Zsh login shell.

The Linux Home Manager layer preserves Athena-specific desktop and terminal applications where they remain supported. Duplicated portable tools move to the common layer. Old version-specific Go, Node.js, and Python packages move to the common mise policy. Removed or renamed packages must be mapped to their maintained Nixpkgs equivalents; silently dropping a user-facing capability is not acceptable. Any capability with no supported equivalent must be recorded in the implementation notes and README.

## Athena hardware boundary

The repository does not contain the generated `hardware-configuration.nix`, and the physical machine is unavailable. The modernization must not guess its actual device IDs, filesystems, kernel modules, or partition layout.

`hosts/athena/hardware-eval.nix` is therefore an explicitly labeled evaluation profile. It supplies only the minimum platform-level declarations required for the NixOS configuration to evaluate. It is not evidence that the configuration is deployable.

The README must state that physical deployment requires generating and reviewing a real hardware configuration on the target machine, then replacing or importing it at the documented hardware boundary. Automated commands may evaluate Athena, but no general command may claim to activation-test it.

## Update and activation flow

Updates follow this sequence:

1. Update `flake.lock` deliberately.
2. Review the input revision diff.
3. Format and statically inspect the repository.
4. Evaluate Gaia and Athena.
5. Build the applicable host where supported.
6. Review the build and activation diff.
7. Activate only through an explicit host-specific command.

Repository commands will distinguish `check`, `build`, and `switch`; checking must never activate. Host-specific targets are preferred over a generic target whose selected host could be ambiguous.

Gaia bootstrap is documented, not hidden behind a curl wrapper:

1. Run the official upstream Nix installer for macOS.
2. Start a shell with Nix available.
3. Run the first nix-darwin activation with per-command `nix-command` and `flakes` features enabled.
4. Use the repository's normal host-specific rebuild command thereafter.

The first activation requires explicit human initiation. This design does not authorize an automated tool or CI job to install Nix or activate nix-darwin on the user's Mac.

## Error handling and safety

- Missing packages, renamed options, type mismatches, and module assertions must fail evaluation before activation.
- Cross-platform checks evaluate foreign host graphs without attempting to execute foreign-platform builds.
- A failed flake update leaves the previous committed lockfile as the rollback point.
- A failed system activation uses native NixOS/nix-darwin generations for rollback; the README documents the relevant commands.
- Home Manager file collisions are resolved by inventorying existing files before the first switch, not by globally forcing overwrites.
- Homebrew `zap` is prohibited during the initial migration because it may remove application data.
- No secret value or private key is copied from environment variables, Ansible vars, dotfiles, or a live home directory into the flake.
- No hardware device path is inferred for Athena.

## Verification strategy

Local verification and a lightweight GitHub Actions workflow will cover:

- Flake metadata and lockfile validity.
- Nix formatting.
- Evaluation of `darwinConfigurations.gaia`.
- Evaluation of `nixosConfigurations.athena`.
- A non-activating Gaia build on an Apple Silicon runner where the available runner supports it.
- Selective full builds where their cost and runner platform make them practical.
- Repository hygiene checks preventing `NIX_PATH`, angle-bracket imports, `builtins.getEnv`, and external dotfiles paths from returning.

Evaluation is mandatory for both hosts. A full Athena desktop build is not mandatory in every CI run because it is large and the hardware profile is evaluation-only. CI must never switch or activate a configuration.

## Acceptance criteria

- Only Gaia and Athena remain as host outputs and documented supported hosts.
- Nixpkgs, Home Manager, and nix-darwin use aligned 26.05 branches and exact revisions in `flake.lock`.
- Both outputs evaluate from a clean checkout without channels, `NIX_PATH`, external dotfiles, or physical-host environment variables.
- Gaia uses the current application inventory from `tmp/config/vars/macos.yml`.
- Portable CLI tools and active user configuration live under `modules/common/home`.
- Oh My Zsh, Git, tmux, Vim, Atuin, direnv, and mise are declarative.
- Homebrew manages only approved GUI/MAS responsibilities and performs no destructive initial cleanup.
- Athena preserves its workstation and service intent and clearly exposes its evaluation-only hardware boundary.
- Existing state versions remain unchanged.
- The README documents bootstrap, updates, checks, builds, activation, rollback, secret exclusions, Homebrew cleanup, mise runtime installation, and the Athena hardware caveat.
- Apollo, Demeter, stale Kratos entry points, channel scripts, obsolete Make targets, Stow integration, `.bash_onstart.sh`, and external dotfile references are removed.
- Automated verification performs no activation.

## References

- [Nix flake concepts](https://nix.dev/concepts/flakes.html)
- [NixOS 26.05 announcement](https://nixos.org/blog/announcements/2026/nixos-2605/)
- [NixOS 26.05 manual](https://nixos.org/manual/nixos/stable/)
- [Nixpkgs 26.05 release notes](https://nixos.org/manual/nixpkgs/stable/release-notes)
- [Home Manager](https://github.com/nix-community/home-manager)
- [Home Manager NixOS module installation](https://github.com/nix-community/home-manager/blob/master/docs/manual/installation/nixos.md)
- [nix-darwin flake installation](https://github.com/nix-darwin/nix-darwin/blob/master/README.md)
- [Official Nix installer](https://nixos.org/download/)

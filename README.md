# Nix system configurations

This repository defines reproducible workstation and user configuration with
Nix flakes, nix-darwin, NixOS, and Home Manager.

## Supported hosts

- `gaia`: Apple Silicon macOS managed by nix-darwin.
- `athena`: x86_64 NixOS workstation. Its checked-in hardware profile is
  evaluation-only and must be replaced before activation.

## Requirements

- GNU Make
- Upstream Nix 2.35 or newer with flakes enabled per command when needed
- Git

## Repository layout

```text
flake.nix
hosts/
  gaia/       # Apple Silicon workstation
  athena/     # Linux workstation
modules/
  workstation/{common,darwin,nixos}
tests/        # Evaluation and contract checks
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

## Check

Run formatting, static checks, shell contracts, and all host evaluations:

```sh
make check
```

Run the focused Athena contract test:

```sh
make test-athena
```

Format the Nix code with the flake formatter:

```sh
make format
```

Checks never activate a system or mutate Homebrew. CI runs the same checks on
Linux and macOS. Darwin-only builds run only in the macOS job; Linux checks
evaluate Gaia without trying to build a Darwin system.

## Build

Build without switching the active generation:

```sh
make build-gaia
make build-athena
```

## Activate

Gaia activation is explicit and requires macOS administrator approval:

```sh
make bootstrap-gaia   # first activation only
make switch-gaia      # subsequent activations
```

`bootstrap-gaia` installs nix-darwin through `nix run`; use `switch-gaia` after
the first successful activation.

The Athena switch target refuses until `hosts/athena/hardware-eval.nix` has
been replaced with a reviewed hardware configuration generated on the physical
host.

## Rollback

Use the native system manager rollback and generation selection tools. Review
the generation before activating a rollback; this repository does not automate
reboot or rollback activation.

## Secrets

Keep tokens, SSH private keys, credentials, decrypted values, and private keys
outside this repository and outside the Nix store.

## Mise

Home Manager declares the approved mise tool versions. After an explicit
activation, install runtimes manually:

```sh
mise install
```

Runtime downloads are never performed by activation hooks or CI.

## Homebrew

Gaia owns only the approved GUI and MAS applications. Homebrew updates,
upgrades, and cleanup are disabled during initial activation; cleanup remains `none` until separately reviewed.

## Hardware

The Athena hardware file uses a tmpfs root solely so its configuration can
evaluate without access to the physical machine. Generate and review a real
hardware configuration on the host before switching.

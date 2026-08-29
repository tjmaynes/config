# Nix workstation configuration

This repository defines reproducible system and user configuration for two hosts using Nix flakes, nix-darwin, NixOS, and Home Manager.

## Supported Hosts

- `gaia`: Apple Silicon macOS managed by nix-darwin.
- `athena`: x86_64 NixOS workstation. Its checked-in hardware profile is evaluation-only.
- `atlas`: x86_64 NixOS home-server foundation. Its hardware profile is
  evaluation-only; Docker applications remain managed by Ansible in
  `tmp/home-server`.

Workstation modules live under `modules/workstation`. Atlas uses focused
`modules/server` modules for identity, security, networking, storage
prerequisites, and Docker. Physical disks, interfaces, device paths, and
secrets are deferred until the server is inventoried.

## Requirements

- GNU Make
- Upstream Nix 2.35 or newer with flakes enabled per command when needed
- Git

## Bootstrap

Install upstream Nix using the official installer in an interactive Terminal, open a fresh login shell, clone this repository, and verify:

```sh
nix --version
nix --extra-experimental-features 'nix-command flakes' flake metadata
```

Do not run an activation during bootstrap. Inventory existing files in the home directory before the first Home Manager activation.

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

Checks never activate a system or mutate Homebrew.

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

The Athena switch target refuses until `hosts/athena/hardware-eval.nix` has been replaced with a reviewed hardware configuration generated on the physical host.

## Rollback

Use the native system manager rollback and generation selection tools. Review the generation before activating a rollback; this repository does not automate reboot or rollback activation.

## Secrets

Keep tokens, SSH private keys, credentials, and machine-specific secrets outside this repository and outside the Nix store. The configuration does not read environment secrets or external dotfile paths.

## Mise

Home Manager declares the approved mise tool versions. After an explicit activation, install runtimes manually:

```sh
mise install
```

Runtime downloads are never performed by activation hooks or CI.

## Homebrew

Gaia owns only the approved GUI and MAS applications. Homebrew updates, upgrades, and cleanup are disabled during initial activation; cleanup remains `none` until separately reviewed.

## Hardware

The Athena and Atlas hardware files use a tmpfs root solely so their
configurations can evaluate without access to the physical machines. Generate
and review real hardware configurations on each host before deployment or
switch. Atlas's Nix layer currently provides Docker and host prerequisites;
Ansible continues to deploy Compose services and their secrets.

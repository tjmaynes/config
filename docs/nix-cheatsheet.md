# Nix cheat sheet

Run repository commands from the repository root. The Makefile enables the
experimental `nix-command` and `flakes` features for its Nix commands. For the
examples using `nix` directly below, enable them in your Nix configuration or
prefix the command with `nix --extra-experimental-features 'nix-command flakes'`
in place of `nix`.

## Core concepts

- **Nix** is a package manager and a language for describing builds and
  configuration. **Nixpkgs** is a collection of packages and modules.
- A **derivation** describes a build. Evaluation computes the description;
  building realizes its outputs in the Nix store, usually under `/nix/store`.
- A **flake** declares inputs and outputs in `flake.nix`. `flake.lock` records
  the resolved input revisions so they can be reused.
- **nix-darwin** manages macOS system configuration. **Home Manager** manages
  user packages and configuration. Both compose Nix modules and their options.
- A **generation** is a version of an activated configuration. Building a
  configuration does not activate it.

## This repository

| Location | Purpose |
| --- | --- |
| `flake.nix` | Inputs, host outputs, formatter, and development shell |
| `flake.lock` | Locked input revisions |
| `hosts/gaia/` | Gaia host facts and module composition |
| `modules/common/` | Portable workstation and user configuration |
| `modules/darwin/` | macOS-specific configuration |
| `tests/` | Unit, smoke, and Nix evaluation tests |

Gaia is an `aarch64-darwin` host; development tooling also supports
`x86_64-linux`. The README describes setup and host-specific behavior.

## Everyday commands

| Command | Effect |
| --- | --- |
| `make format` | Format Nix and Python files |
| `make format-check` | Check formatting without changing files |
| `make lint` | Run static checks |
| `make test` | Run all tests |
| `make test-unit` | Run file-only unit tests |
| `make test-smoke` | Run flake smoke tests |
| `make test-integration` | Run Nix evaluation tests |
| `make eval` | Evaluate Gaia's system derivation path |
| `make check` | Run formatting checks, lint, tests, and evaluation |
| `make build` | Build Gaia's system without activating it or creating a `result` link |
| `make update` | Update all flake inputs in `flake.lock` |
| `make update-unstable` | Update the `nixpkgs-unstable` input |
| `make update-home-manager` | Update the `home-manager` input |

Review lock-file changes after updates. `make bootstrap` and `make deploy`
activate Gaia and have host-level effects; run them only when activation is
explicitly requested and its impact is accepted. See the README for the
first-activation distinction and rollback guidance.

## Explore a flake

```sh
nix flake metadata             # Inspect inputs and lock information
nix flake show                # List flake outputs
nix develop                   # Enter the repository's development shell
nix develop --command python --version
nix eval --raw .#darwinConfigurations.gaia.config.system.build.toplevel.drvPath
nix build .#darwinConfigurations.gaia.system --no-link
```

`.` refers to the current flake; `#` selects an output. `nix eval` evaluates an
expression, while `nix build` also realizes the selected output. Build outputs
may be downloaded from a cache or built locally. A local Git flake normally
includes tracked files; stage new files before expecting them to appear in its
source snapshot.

## Nix language essentials

```nix
# Attribute sets use semicolons; lists use whitespace.
{
  name = "Gaia";
  enabled = true;
  packages = [ "git" "vim" ];
  editor.fontSize = 16; # Nested attribute path
}
```

```nix
let
  greeting = "Hello";
in
"${greeting}, Nix" # String interpolation
```

```nix
# A function accepting a set of arguments, as many modules do.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [ git vim ];
}
```

`with pkgs;` makes package names available in the following expression.
`config` contains the merged configuration, and `pkgs` supplies packages.
A module can define options in multiple files; the module system merges those
values according to each option's type and priority.

## Useful references

- [Nix language basics](https://nix.dev/tutorials/nix-language.html)
- [Nix reference manual](https://nix.dev/manual/nix/2.35/)
- [Home Manager manual](https://nix-community.github.io/home-manager/)
- [nix-darwin documentation](https://nix-darwin.github.io/nix-darwin/manual/)

# Athena development server

Approved in chat on 2026-11-04: prepare a headless NixOS MS-A2 named `athena`,
with SSH, code-server behind the home server's Tailscale/Caddy proxy at
`https://coding.bewoogie.local`, and a persistent Codex service at boot.

## Approach

Use a NixOS flake output and the upstream NixOS code-server and Tailscale
modules. Reuse portable Home Manager development configuration without Gaia's
graphical applications or mail profile. Keep Gaia's behavior unchanged.
The alternative was starting Codex on demand through desktop SSH connections;
the user selected a persistent service instead.

The pinned Home Manager source (`b787c48e2ec57a9d098f5c2721882a3bc1e16f97`)
and current upstream Codex source/options/manual were inspected. They provide
package/settings/skills integration, but no persistent Codex service option.
Use a small NixOS systemd unit for that gap, without updating dependencies.

## Contracts

- `x86_64-linux`, hostname `athena`, user `tjmaynes`, home `/home/tjmaynes`.
- Codex app-server starts at boot as that user; private Unix socket
  `/run/codex/app-server.sock`, restart on failure, persistent `~/.codex` state.
  Connect over SSH with the CLI's `--remote unix://` transport. Desktop SSH
  integration can independently manage its own server.
- code-server starts at boot as the same user on TCP 8080, password auth with a
  required runtime environment file `/var/lib/athena/code-server.env`.
- Permit SSH and code-server on `tailscale0` only; no public Codex listener.
  Tailscale enrollment and all credentials are manual, outside the Nix store.
- Caddy/DNS remain owned by the separate home-server repository. Document the
  backend `http://<athena-tailscale-ip>:8080` and existing internal CA trust.
- Provide an explicit UEFI/ext4 disk-label template, to replace with generated
  hardware configuration during installation. Do not partition, activate, or
  enroll devices as part of preparation.
- Extend Makefile evaluation/build interfaces, README, agent guide, and tests.
  Evaluate both hosts on macOS; actual Athena builds run on Linux or a builder.

## Validation

Evaluation tests check boot targets, service identities, socket transport,
runtime secrets, firewall scope, headless packages, shared Codex settings,
and NixOS toplevel evaluation. Run repository format, lint, test, and eval
targets. Runtime boot, auth, proxy, and hardware tests await the machine.

Sources: https://learn.chatgpt.com/docs/app-server,
https://nix-community.github.io/home-manager/options/home-manager/programs/codex.html,
https://github.com/nix-community/home-manager/tree/master/modules/programs/codex.

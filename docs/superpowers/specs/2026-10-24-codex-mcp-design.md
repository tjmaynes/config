# Nix-managed Codex settings and MCP connections

Status: hybrid design approved; simplified at the user's request to use upstream
Home Manager `programs.codex.mutableSettings`, shared MCP integration, and native
project configuration.

## Intent

Nix declares Codex preferences and MCP connections while Codex keeps its user
configuration writable. Preserve existing settings unless explicitly overridden.
Keep credentials outside Git and the Nix store. Work on main as requested.

## Approach

Use Home Manager's native Codex module with the existing unstable Codex package:
`programs.codex.enable = true` and `programs.codex.mutableSettings = true`.
This replaces the proposed custom Python merger and ownership tracking.

Declare the user's selected default model `gpt-5.6-terra` alongside their current
`medium` reasoning effort, `pragmatic` personality, and `features.js_repl = false`.
Keep notification commands, shell environment, plugins, project trust, and UI
state under Codex's mutable ownership pending any separate portability review.

- Enable `programs.mcp` and declare the default `n8n` URL in its shared registry:
  `https://n8n.tjmaynes.com/mcp-server/http`. Set
  `programs.codex.enableMcpIntegration = true` to consume the registry.
- Sproutup owns its native project config at
  `/Users/tjmaynes/workspace/notebook/development/consulting/sproutup/.codex/config.toml`
  with `[mcp_servers.n8n]` pointing to
  `https://sproutupdigital.n8n.io/mcp-server/http`. Add only this override while
  preserving any existing settings. No Nix profile, project guard, or project
  activation script remains. Workstation activation does not require this folder.
- Preserve existing skill deployment. Do not manage project trust or authenticate
  during activation. Project config applies when starting a task in a trusted
  project, allowing concurrent tasks to use different endpoints.

Whole-file immutable configuration was rejected because Codex writes its own
settings. A proxy adds a daemon that this task does not require. A custom merger
duplicates upstream behavior and is no longer part of the design.

## Upstream semantics and dependency

Declared values win during activation. The merger preserves setting values, but
may normalize formatting and remove comments. Removed declarations leave their
old values in the writable file until explicitly removed. New files use `0600`.
No custom backup, ownership-state, or removal mechanism is added.

The locked release-26.05 Home Manager lacks this option. Update only its input
to master and pin it in flake.lock. Nixpkgs and nix-darwin stay on 26.05. Retain
and disclose Home Manager's 26.11/26.05 version-mismatch warning.

## Validation and delivery

Add focused Nix evaluation checks for native mutable settings, shared MCP
integration, the default URL, and absence of project-specific Home Manager
configuration and immutable live-config home.file entries. Parse and inspect the
native project TOML separately in its own repository.
Run `make format-check`, `make lint`, `make test`, and `make eval`; obtain code
review. Preserve unrelated `PLAN.md` and `RESEARCH.md`. Do not activate Gaia,
authenticate, or modify the global Codex config. The user authorized creating the
native project override separately. Endpoint connectivity is unverified.

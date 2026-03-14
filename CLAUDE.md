# Claude Code Guide

See [AGENTS.md](AGENTS.md) for project structure, coding conventions, tooling, and workflow expectations.

## Key Reminders

- Run `make format` after modifying any Ansible YAML files
- Use FQCNs for all Ansible modules (e.g., `ansible.builtin.file`, `community.general.homebrew`)
- Use `ansible_facts.*` syntax, not legacy `ansible_env` / `ansible_distribution`
- Use conventional commits (`feat:`, `fix:`, `chore:`, `refactor:`)
- `GITHUB_TOKEN` env var is required for `make setup` and `make backup_github_repos`

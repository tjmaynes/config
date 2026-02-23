# Project Agent Guide

> Scope: Root project (applies to all subdirectories unless overridden)

## Quick Facts

- **Primary language:** YAML (Ansible playbooks) + Bash (scripts)
- **Package manager:** pip (Python venv) + Homebrew (macOS packages)
- **Automation:** GNU Make
- **Supported platforms:** macOS
- **CI/CD:** None (local provisioning only)

## Repository Tour

```
.
├── Makefile                 # All automation entry points
├── ansible.cfg              # Ansible configuration
├── playbooks/
│   ├── setup_macos.yml      # Main macOS provisioning playbook
│   └── teardown.yml         # Machine teardown playbook
├── requirements.txt         # Python dependencies (ansible, etc.)
├── collections/
│   └── requirements.yml     # Ansible Galaxy collections and roles
├── inventory/
│   └── hosts.ini            # Ansible inventory (localhost)
├── roles/                   # Custom Ansible roles
│   ├── common/              # SSH configuration
│   ├── dotfiles/            # Dotfile management
│   ├── git/                 # Git configuration and aliases
│   ├── macos/               # macOS system preferences
│   ├── mise/                # mise runtime version manager
│   ├── teardown/            # Machine teardown tasks
│   ├── vim/                 # Vim configuration
│   └── zsh/                 # Zsh and Oh My Zsh setup
├── scripts/
│   ├── install.sh           # OS detection + venv + pip + galaxy install
│   ├── setup.sh             # OS detection + ansible-playbook runner
│   └── backup_git_repos.sh  # GitHub repo backup via API
└── vars/
    ├── common.yml           # Shared vars (timezone, workspace, SSH keys)
    ├── git.yml              # Git identity, aliases, tool config
    └── macos.yml            # Homebrew packages, cask apps, system prefs
```

Roles prefixed with a vendor name (e.g., `elliotweiser.osx-command-line-tools`, `gantsign.visual-studio-code`) are installed via Ansible Galaxy and listed in `.gitignore`. Do not edit them directly.

## Tooling & Setup

- **Python 3** and **virtualenv** — the venv lives at `.venv/` (gitignored)
- **GNU Make** — all commands go through the Makefile
- **Ansible 9.3.0** — installed into the venv via `requirements.txt`
- **Homebrew** — installed automatically by `scripts/install.sh` on macOS

### Required Environment Variables

| Variable | Purpose |
|----------|---------|
| `GITHUB_TOKEN` | Required by `make setup` and `make backup_github_repos`. Used for Git role and GitHub API access. |

### First-time Setup

```bash
make install    # Creates venv, installs pip deps and Galaxy roles
make setup      # Runs the ansible-playbook for your OS (prompts for sudo)
```

Or combined:

```bash
make bootstrap  # Runs install then setup
```

## Common Tasks

| Command | What It Does |
|---------|-------------|
| `make install` | Creates `.venv`, installs Python deps and Ansible Galaxy collections/roles |
| `make setup` | Detects OS, activates venv, runs the matching `setup_<os>.yml` playbook |
| `make bootstrap` | Runs `install` then `setup` |
| `make teardown` | Runs `playbooks/teardown.yml` playbook to remove provisioned config |
| `make format` | Runs `ansible-lint --fix .` to auto-format Ansible files |
| `make backup_github_repos GITHUB_PROFILE=<user> BACKUP_DIR=<dir>` | Clones/pulls all GitHub repos for a user |

## Testing & Quality Gates

- **Linting/formatting:** `make format` runs `ansible-lint --fix .` across all YAML files
- **No automated test suite** — changes are validated by running `make setup` on a target machine
- Always run `make format` before committing Ansible changes

## Workflow Expectations

- **Branch model:** Work on `main` directly (personal config repo)
- **Commits:** Use conventional commit format (`feat:`, `fix:`, `chore:`, etc.)
- **Adding packages:** Edit `vars/macos.yml` for Homebrew packages/casks or Mac App Store apps
- **Adding roles:** Create a new directory under `roles/` with standard Ansible role structure (`tasks/`, `defaults/`, `vars/`, `handlers/`). Reference it in the appropriate `setup_*.yml` playbook.
- **Adding Galaxy dependencies:** Add to `collections/requirements.yml` and re-run `make install`
- **Scripts:** Bash scripts go in `scripts/`. Keep them POSIX-friendly and use `set -e`.

## Documentation Duties

- Update `README.md` when adding new Makefile targets, roles, or changing setup requirements
- Keep the Roles table in `README.md` in sync when adding or removing custom roles
- Update `vars/*.yml` comments when changing variable semantics

## Finish the Task Checklist

- [ ] Run `make format` if any Ansible YAML files were modified
- [ ] Update `README.md` if significant changes landed (new targets, roles, or requirements)
- [ ] Summarize changes in conventional commit format (e.g., `feat: add docker role`, `fix: correct homebrew path on ARM`)

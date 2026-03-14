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
├── requirements.txt         # Python dependencies (ansible, ansible-lint, etc.)
├── collections/
│   └── requirements.yml     # Ansible Galaxy collections (community.general, community.crypto, ansible.posix)
├── inventory/
│   └── hosts.ini            # Ansible inventory (localhost)
├── roles/                   # Custom Ansible roles
│   ├── common/              # SSH configuration and timezone
│   ├── dotfiles/            # Dotfile management via GNU stow
│   ├── git/                 # Git configuration, aliases, and project backup
│   ├── macos/               # Homebrew packages/casks, MAS apps, and system preferences
│   ├── mise/                # mise runtime version manager
│   ├── teardown/            # Machine teardown tasks
│   ├── vim/                 # Vim and vim-plug setup
│   └── zsh/                 # Zsh, Oh My Zsh, and shell environment
├── scripts/
│   ├── install.sh           # OS detection + venv + pip + galaxy install
│   ├── setup.sh             # OS detection + ansible-playbook runner
│   └── backup-git-repos.sh  # GitHub repo backup via API
└── vars/
    ├── common.yml           # Shared vars (timezone, workspace, SSH keys)
    ├── git.yml              # Git identity, aliases, tool config
    └── macos.yml            # Homebrew taps/packages/casks, MAS apps, system prefs
```

All Galaxy dependencies are collections only (no third-party roles). All roles under `roles/` are custom.

## Tooling & Setup

- **Python 3** and **virtualenv** — the venv lives at `.venv/` (gitignored)
- **GNU Make** — all commands go through the Makefile
- **Ansible >=13.4.0** — installed into the venv via `requirements.txt`
- **ansible-lint >=26.3.0** — linting and formatting
- **Homebrew** — installed automatically by `scripts/install.sh` on macOS

### Required Environment Variables

| Variable | Purpose |
|----------|---------|
| `GITHUB_TOKEN` | Required by `make setup` and `make backup_github_repos`. Used for Git role and GitHub API access. |

### First-time Setup

```bash
make install    # Creates venv, installs pip deps and Galaxy collections
make setup      # Runs the ansible-playbook for your OS (prompts for sudo)
```

Or combined:

```bash
make bootstrap  # Runs install then setup
```

## Common Tasks

| Command | What It Does |
|---------|-------------|
| `make install` | Creates `.venv`, installs Python deps and Ansible Galaxy collections |
| `make setup` | Detects OS, activates venv, runs the matching `setup_<os>.yml` playbook |
| `make bootstrap` | Runs `install` then `setup` |
| `make teardown` | Runs `playbooks/teardown.yml` playbook to remove provisioned config |
| `make format` | Runs `ansible-lint --fix .` to auto-format Ansible files |
| `make backup_github_repos BACKUP_DIR=<dir>` | Clones/pulls all GitHub repos for the authenticated user |

## Coding Conventions

- **FQCNs required**: All modules must use fully qualified collection names (e.g., `ansible.builtin.file`, `community.general.homebrew`)
- **Facts syntax**: Use `ansible_facts.env.HOME` / `ansible_facts.distribution` (not legacy `ansible_env` / `ansible_distribution`)
- **Static includes**: Use `ansible.builtin.import_tasks` for unconditional includes
- **None checks**: Use `is not none` (not `!= None`)
- **Command checks**: Use `which` for binary existence checks with `failed_when: result.rc != 0`

## Testing & Quality Gates

- **Linting/formatting:** `make format` runs `ansible-lint --fix .` across all YAML files
- **Target profile:** ansible-lint must pass at `production` profile with 0 failures, 0 warnings
- **No automated test suite** — changes are validated by running `make setup` on a target machine
- Always run `make format` before committing Ansible changes

## Workflow Expectations

- **Branch model:** Work on `main` directly (personal config repo)
- **Commits:** Use conventional commit format (`feat:`, `fix:`, `chore:`, etc.)
- **Adding packages:** Edit `vars/macos.yml` — add taps to `homebrew_taps`, packages to `homebrew_installed_packages`, cask apps to `homebrew_cask_apps`, or MAS apps to `mas_installed_apps`
- **Adding roles:** Create a new directory under `roles/` with standard Ansible role structure (`tasks/`, `defaults/`, `vars/`, `handlers/`). Reference it in the appropriate `setup_*.yml` playbook.
- **Adding Galaxy collections:** Add to `collections/requirements.yml` and re-run `make install`
- **Scripts:** Bash scripts go in `scripts/`. Keep them POSIX-friendly and use `set -e`.

## Documentation Duties

- Update `README.md` when adding new Makefile targets, roles, or changing setup requirements
- Keep the Roles table in `README.md` in sync when adding or removing custom roles
- Update `vars/*.yml` comments when changing variable semantics

## Finish the Task Checklist

- [ ] Run `make format` if any Ansible YAML files were modified
- [ ] Update `README.md` if significant changes landed (new targets, roles, or requirements)
- [ ] Summarize changes in conventional commit format (e.g., `feat: add docker role`, `fix: correct homebrew path on ARM`)

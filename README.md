# config

> Ansible playbook for provisioning my developer workstations.

## Supported Platforms

- macOS

## Requirements

- [GNU Make](https://www.gnu.org/software/make/)
- Python 3
- `GITHUB_TOKEN` environment variable (for setup and backup tasks)

## Usage

To bootstrap a machine (install dependencies and run setup):
```bash
make bootstrap
```

To install project dependencies:
```bash
make install
```

To set up a machine:
```bash
make setup
```

To teardown a machine:
```bash
make teardown
```

To format Ansible files:
```bash
make format
```

To backup GitHub repositories:
```bash
make backup_github_repos BACKUP_DIR=<directory>
```

## Roles

| Role | Description |
|------|-------------|
| `common` | SSH configuration and timezone setup |
| `dotfiles` | Dotfile management via GNU stow |
| `git` | Git configuration, aliases, and project backup |
| `macos` | Homebrew packages/casks, Mac App Store apps, and system preferences (dock, hostname, trackpad, screen) |
| `mise` | [mise](https://mise.jdx.dev/) runtime version manager |
| `teardown` | Machine teardown (unstow dotfiles) |
| `vim` | Vim and vim-plug setup |
| `zsh` | Zsh, Oh My Zsh, and shell environment setup |

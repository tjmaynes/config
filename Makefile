install:
	chmod +x ./scripts/install.sh
	./scripts/install.sh

setup:
	chmod +x ./scripts/setup.sh
	./scripts/setup.sh

bootstrap: install setup

teardown:
	. .venv/bin/activate; ansible-playbook teardown.yml --ask-become-pass \
		--inventory-file inventory/hosts.ini

backup_github_repos:
	@if [ -z "$(GITHUB_PROFILE)" ] || [ -z "$(BACKUP_DIR)" ]; then \
		echo "Usage: make backup_github_repos GITHUB_PROFILE=<username> BACKUP_DIR=<directory>"; \
		echo ""; \
		echo "Example: make backup_github_repos GITHUB_PROFILE=tjmaynes BACKUP_DIR=/backup/repos"; \
		exit 1; \
	fi
	chmod +x ./scripts/backup_git_repos.sh
	./scripts/backup_git_repos.sh $(GITHUB_PROFILE) $(BACKUP_DIR)

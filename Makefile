install:
	chmod +x ./scripts/install.sh
	./scripts/install.sh

setup:
	chmod +x ./scripts/setup.sh
	./scripts/setup.sh

bootstrap: install setup

teardown:
	. .venv/bin/activate; ansible-playbook playbooks/teardown.yml --ask-become-pass \
		--inventory-file inventory/hosts.ini \
		-e ansible_python_interpreter=$$PWD/.venv/bin/python

format:
	. .venv/bin/activate; ansible-lint --fix .

backup_github_repos:
	@if [ -z "$(BACKUP_DIR)" ]; then \
		echo "Usage: make backup_github_repos BACKUP_DIR=<directory>"; \
		echo ""; \
		echo "Example: make backup_github_repos BACKUP_DIR=/backup/repos"; \
		exit 1; \
	fi
	chmod +x ./scripts/backup_git_repos.sh
	./scripts/backup_git_repos.sh $(BACKUP_DIR)

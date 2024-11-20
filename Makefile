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

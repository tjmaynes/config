install:
	chmod +x ./scripts/install.sh
	./scripts/install.sh

setup:
	. .venv/bin/activate; ansible-playbook setup.yml --ask-become-pass \
		--inventory-file inventory/hosts.ini

bootstrap: install setup

teardown:
	. .venv/bin/activate; ansible-playbook teardown.yml --ask-become-pass \
		--inventory-file inventory/hosts.ini

install:
	chmod +x ./scripts/install.sh
	./scripts/install.sh

setup:
	. .venv/bin/activate; ansible-playbook ./ansible/setup.yml --ask-become-pass \
		--inventory-file ./ansible/inventory/hosts.ini

bootstrap: install bootstrap

teardown:
	. .venv/bin/activate; ansible-playbook ./ansible/teardown.yml --ask-become-pass \
		--inventory-file ./ansible/inventory/hosts.ini

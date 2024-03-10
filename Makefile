install:
	chmod +x ./scripts/install.sh
	./scripts/install.sh

setup:
	ansible-playbook ./ansible/setup.yml --ask-become-pass \
		--inventory-file ./ansible/inventory/hosts.ini

teardown:
	ansible-playbook ./ansible/teardown.yml --ask-become-pass \
		--inventory-file ./ansible/inventory/hosts.ini

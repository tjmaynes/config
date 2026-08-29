NIX := nix --extra-experimental-features 'nix-command flakes'

fmt:
	$(NIX) fmt

format-check:
	$(NIX) develop --command nixfmt --check $$(find . -type f -name '*.nix' -not -path './.git/*' -print | sort)

lint:
	$(NIX) develop --command statix check .
	$(NIX) develop --command deadnix --fail .
	$(NIX) develop --command shellcheck tests/*.sh
	$(NIX) develop --command actionlint

test:
	$(NIX) develop --command sh tests/flake-bootstrap.sh
	$(NIX) develop --command sh tests/common-eval.sh
	$(NIX) develop --command sh tests/gaia.sh
	$(NIX) develop --command sh tests/athena.sh
	$(NIX) develop --command sh tests/atlas.sh
	$(NIX) develop --command sh tests/hygiene.sh
	$(NIX) develop --command sh tests/docs.sh

eval-gaia:
	$(NIX) eval --raw .#darwinConfigurations.gaia.config.system.build.toplevel.drvPath

eval-athena:
	$(NIX) eval --raw .#nixosConfigurations.athena.config.system.build.toplevel.drvPath

eval-atlas:
	$(NIX) eval --raw .#nixosConfigurations.atlas.config.system.build.toplevel.drvPath

check: format-check lint test eval-gaia eval-athena eval-atlas

build-gaia:
	$(NIX) build .#darwinConfigurations.gaia.system --no-link

build-athena:
	$(NIX) build .#nixosConfigurations.athena.config.system.build.toplevel --no-link

bootstrap-gaia:
	sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .#gaia

switch-gaia:
	sudo darwin-rebuild switch --flake .#gaia

switch-athena:
	@echo "Refusing switch: replace hosts/athena/hardware-eval.nix with reviewed hardware configuration first." >&2
	@exit 1

update:
	$(NIX) flake update

.PHONY: fmt format-check lint test check update bootstrap-gaia switch-gaia switch-athena eval-gaia eval-athena eval-atlas build-gaia build-athena

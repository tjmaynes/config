NIX := nix --extra-experimental-features 'nix-command flakes'

format:
	$(NIX) fmt -- $$(find . -type f -name '*.nix' -not -path './.git/*' -print | sort)
	$(NIX) develop --command ruff format --config tests/pyproject.toml tests

format-check:
	$(NIX) develop --command nixfmt --check $$(find . -type f -name '*.nix' -not -path './.git/*' -print | sort)
	$(NIX) develop --command ruff format --check --config tests/pyproject.toml tests

lint:
	$(NIX) develop --command statix check .
	$(NIX) develop --command deadnix --fail .
	$(NIX) develop --command ruff check --config tests/pyproject.toml tests
	$(NIX) develop --command actionlint

test:
	$(NIX) develop --command python -m unittest discover -s tests -t . -v

test-unit:
	$(NIX) develop --command python -m unittest discover -s tests/unit -t . -v

test-smoke:
	$(NIX) develop --command python -m unittest discover -s tests/smoke -t . -v

test-integration:
	$(NIX) develop --command python -m unittest discover -s tests/integration -t . -v

eval:
	$(NIX) eval --raw .#darwinConfigurations.gaia.config.system.build.toplevel.drvPath

check: format-check lint test eval

build:
	$(NIX) build .#darwinConfigurations.gaia.system --no-link

bootstrap:
	sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake .#gaia

switch:
	sudo darwin-rebuild switch --flake .#gaia

update:
	$(NIX) flake update

update-unstable:
	$(NIX) flake update nixpkgs-unstable

update-home-manager:
	$(NIX) flake update home-manager

.PHONY: format format-check lint test test-unit test-smoke test-integration check update update-unstable update-home-manager bootstrap switch build eval

"""Shared process boundary for evaluation-only Nix tests."""

import json
import shlex
import subprocess
from functools import cache
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOSTS = {
    "gaia": ".#darwinConfigurations.gaia.config",
}
USER = "home-manager.users.tjmaynes"
PACKAGE_PNAMES = 'packages: map (package: package.pname or "") packages'
PACKAGE_NAMES = 'packages: map (package: package.name or "") packages'


def run_nix(*args: str) -> str:
    command = ["nix", "--extra-experimental-features", "nix-command flakes", *args]
    try:
        result = subprocess.run(
            command, cwd=ROOT, capture_output=True, text=True, check=False
        )
    except OSError as error:
        raise AssertionError(
            f"Cannot run {shlex.join(command)}: {error}. "
            "Install Nix and use the repository development shell."
        ) from error
    if result.returncode:
        raise AssertionError(
            f"{shlex.join(command)} exited with status {result.returncode}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result.stdout


@cache
def eval_json(attribute: str, *, apply: str | None = None) -> object:
    args = ["eval", "--json"]
    if apply is not None:
        args.extend(["--apply", apply])
    output = run_nix(*args, attribute)
    try:
        return json.loads(output)
    except json.JSONDecodeError as error:
        raise AssertionError(
            f"Invalid JSON evaluating {attribute}: {output}"
        ) from error


@cache
def eval_raw(attribute: str) -> str:
    return run_nix("eval", "--raw", attribute)

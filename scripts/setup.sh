#!/usr/bin/env bash

set -e

function check_requirements() {
  if [[ ! -f ".venv/bin/activate" ]]; then
    echo "Run install script before running this script..."
    exit 1
  fi
}

function main() {
  check_requirements

  case "$OSTYPE" in
    linux-gnu*) CONFIG_OS_TYPE=debian ;;
    darwin*)    CONFIG_OS_TYPE=macos ;; 
    *)          echo "Unable to run install script on this '$OSTYPE' operating system..." ; exit 1 ;;
  esac

  . .venv/bin/activate

  ansible-playbook setup_$CONFIG_OS_TYPE.yml --ask-become-pass \
    --inventory-file inventory/hosts.ini
}

main

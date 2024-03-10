#!/usr/bin/env bash

set -e

function install_homebrew() {
  if [[ -z "$(command -v brew)" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    if [[ $(uname -m) == 'arm64' ]]; then
      export PATH="/opt/homebrew/bin:$PATH" >> "$HOME/.zshrc"
      echo "eval $(/opt/homebrew/bin/brew shellenv)" >> "$HOME/.zshrc"

      /opt/homebrew/bin/brew shellenv
    else
      export PATH="/usr/local/bin:$PATH" >> "$HOME/.zshrc"
      echo "eval $(/usr/local/bin/brew shellenv)" >> "$HOME/.zshrc"

      /usr/local/bin/brew shellenv
    fi
  fi
}

function install_python() {
  if [[ -z "$(command -v python)" ]]; then
    brew install python3
  fi
}

function main() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    install_homebrew
    install_python
  fi

  ansible-galaxy install \
    -r ./ansible/collections/requirements.yml \
    --force
}

main

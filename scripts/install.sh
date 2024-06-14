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
  if [[ -z "$(command -v python3)" ]]; then
    brew install python3
  fi
}

function setup_macos() {
  install_homebrew
  install_python

  OPENSSL_LOCATION=$(brew --prefix openssl)
  export LDFLAGS="-I/$OPENSSL_LOCATION/include -L/$OPENSSL_LOCATION/lib"
}

function setup_virtualenv() {
  if [[ -z "$(command -v pip3)" ]]; then
    python3 -m pip install --upgrade pip
  fi

  if [[ -z "$(command -v virtualenv)" ]]; then
    brew install virtualenv
  fi

  test -d .venv || virtualenv .venv
  source .venv/bin/activate
}

function accept_xcode_license() {
  XCODE_VERSION=$(xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space]]+([0-9\.]+)/\1/')
  ACCEPTED_LICENSE_VERSION=$(defaults read /Library/Preferences/com.apple.dt.Xcode 2> /dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '"' -f 2)

  if [ "$XCODE_VERSION" != "$ACCEPTED_LICENSE_VERSION" ]; then
    sudo xcodebuild -license
  fi
}

function main() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    setup_macos
  else
    echo "Unable to run install script on this '$OSTYPE' operating system..."
    exit 1
  fi

  setup_virtualenv

  python3 -m pip install --no-cache -r requirements.txt

  ansible-galaxy install \
    -r collections/requirements.yml \
    --force
}

main
#!/usr/bin/env bash

set -e

function setup_debian() {
  sudo apt update -y

  sudo apt autoremove -y

  sudo apt upgrade -y

  sudo apt install -y \
    git \
    make \
    python3 \
    python3-pip \
    python3-virtualenv \
    ubuntu-desktop
}

function accept_xcode_license() {
  XCODE_VERSION=$(xcodebuild -version | grep '^Xcode\s' | sed -E 's/^Xcode[[:space]]+([0-9\.]+)/\1/')
  ACCEPTED_LICENSE_VERSION=$(defaults read /Library/Preferences/com.apple.dt.Xcode 2> /dev/null | grep IDEXcodeVersionForAgreedToGMLicense | cut -d '"' -f 2)

  if [ "$XCODE_VERSION" != "$ACCEPTED_LICENSE_VERSION" ]; then
    sudo xcodebuild -license
  fi
}

function install_homebrew() {
  # accept_xcode_license

  if [[ -z "$(command -v brew)" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    if [[ $(uname -m) == 'arm64' ]]; then
      export PATH="/opt/homebrew/bin:$PATH" >> "$HOME/.zshrc"

      /opt/homebrew/bin/brew shellenv
    else
      export PATH="/usr/local/bin:$PATH" >> "$HOME/.zshrc"

      /usr/local/bin/brew shellenv
    fi
  fi
}

function setup_macos() {
  install_homebrew

  if [[ -z "$(command -v python3)" ]]; then
    brew install python3
  fi

  OPENSSL_LOCATION=$(brew --prefix openssl)
  export LDFLAGS="-I/$OPENSSL_LOCATION/include -L/$OPENSSL_LOCATION/lib"

  if [[ -z "$(command -v virtualenv)" ]]; then
    brew install virtualenv
  fi
}

function main() {
  case "$OSTYPE" in
    linux-gnu*) setup_debian ;;
    darwin*)    setup_macos ;; 
    *)          echo "Unable to run install script on this '$OSTYPE' operating system..." ; exit 1 ;;
  esac

  test -d .venv || python3 -m venv .venv
  . .venv/bin/activate

  pip3 install --no-cache -r requirements.txt

  ansible-galaxy install \
    -r collections/requirements.yml \
    --force
}

main

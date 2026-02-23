#!/usr/bin/env bash

set -e

function check_requirements() {
    if [[ ! -f ".venv/bin/activate" ]]; then
        echo "Run install script before running this script..."
        exit 1
    elif [[ -z "$GITHUB_TOKEN" ]]; then
        echo "Please ensure GITHUB_TOKEN env var is available before running this script..."
        exit 1
    fi
}

function detect_linux_distribution() {
    if [[ ! -f "/etc/os-release" ]]; then
        echo "Unable to detect Linux distribution: /etc/os-release not found"
        exit 1
    fi

    # Source the file and extract the ID
    # shellcheck disable=SC1091
    . /etc/os-release

    echo "$ID"
}

function main() {
    check_requirements

    case "$OSTYPE" in
        linux-gnu*)
            LINUX_DISTRO=$(detect_linux_distribution)
            case "$LINUX_DISTRO" in
                arch)
                    CONFIG_OS_TYPE=arch
                    ;;
                *)
                    echo "Unsupported Linux distribution: $LINUX_DISTRO"
                    echo "Only Arch Linux and macOS are supported."
                    exit 1
                    ;;
            esac
            ;;
        darwin*)
            CONFIG_OS_TYPE=macos
            ;;
        *)
            echo "Unable to run setup script on this '$OSTYPE' operating system..."
            exit 1
            ;;
    esac

    . .venv/bin/activate

    ansible-playbook playbooks/setup_$CONFIG_OS_TYPE.yml --ask-become-pass \
        --inventory-file inventory/hosts.ini \
        -e ansible_python_interpreter="$PWD/.venv/bin/python"
}

main

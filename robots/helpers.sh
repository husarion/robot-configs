#!/bin/bash

check_user() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "Error: This script must be run as a normal user."
        exit 1
    fi
}

print_header() {
  echo -e "\n$1"
  echo "---------------------------------------"
}

reinstall_snaps() {
    local version="$1"
    shift
    local snaps=("$@")
    for snap in "${snaps[@]}"; do
        sudo snap remove "$snap"

        sudo snap install "$snap" --channel="$version/stable"
        sudo snap set "$snap" \
            ros.transport=udp-lo \
            ros.localhost-only='' \
            ros.domain-id=0 \
            ros.namespace=''

    # disable auto-refresh (auto update)
    # sudo snap refresh --hold=forever $snap
    done
}
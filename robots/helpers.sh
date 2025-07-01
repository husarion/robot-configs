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

ask_to_install_snaps() {
    local snaps=("$@")
    read -p "Do you want to install additional snaps (${snaps[*]})? [y/N]: " install_additional
    if [[ "$install_additional" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

reinstall_snaps() {
    local snaps=("$@")
    for snap in "${snaps[@]}"; do
        sudo snap remove "$snap"

        sudo snap install "$snap" --channel="$ROS_DISTRO"/stable
        sudo snap set "$snap" \
            ros.transport=udp-lo \
            ros.localhost-only='' \
            ros.domain-id=0 \
            ros.namespace=''

    # disable auto-refresh (auto update)
    # sudo snap refresh --hold=forever $snap
    done
}
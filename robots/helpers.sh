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
        sudo snap stop "$snap" &> /dev/null || true
    done

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

set_robot_env() {
  local name="$1"
  local value="$2"
  local env_file="/etc/environment"
  [ -f "$env_file" ] || touch "$env_file"

  if grep -q "^$name=" "$env_file"; then
    sudo sed -i "s/^$name=.*/$name=$value/" "$env_file"
  else
    echo "$name=$value" | sudo tee -a "$env_file" > /dev/null
  fi
}
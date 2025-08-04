#!/bin/bash
set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP_LIST=(rosbot husarion-depthai husarion-rplidar husarion-webui)
ROBOT_MODEL=rosbot
LAYOUT_FILE="$SCRIPT_DIR/foxglove-rosbot.json"
VALID_CONFIGURATIONS=("3" "3_pro")

# ─── force root execution and remember the caller ──────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "Please start this script with: sudo $0 <configuration>" >&2
    exit 1
fi
ORIG_USER="${SUDO_USER:-root}"   # the login that invoked sudo

# Functions
print_usage() {
echo -e "\e[1mInvalid configuration.\e[0m"
  echo "Usage: $0 <configuration>"
  echo "Valid configurations:"
  for config in "${VALID_CONFIGURATIONS[@]}"; do
      echo "  - $config"
  done  
}

# Source
source "/etc/environment"
if [ -f "$SCRIPT_DIR/../../helpers.sh" ]; then
    source "$SCRIPT_DIR/../../helpers.sh" # Working inside repo
else
    source "$SCRIPT_DIR/helpers.sh" # Working on Husarion OS after setup_robot_configuration
fi

# Main
start_time=$(date +%s)

configuration="$1"

if [[ -n "$configuration" ]]; then
    if [[ " ${VALID_CONFIGURATIONS[@]} " =~ " ${configuration} " ]]; then
        set_env "ROBOT_CONFIGURATION" "$configuration"
    else
        print_usage
        exit 1
    fi
else
    if [[ -n "$ROBOT_CONFIGURATION" ]]; then
        echo -e "Default robot configuration '${ROBOT_CONFIGURATION}' will be used."
        configuration="$ROBOT_CONFIGURATION"
    else
        print_usage
        exit 1
    fi
fi

print_header "Reinstall snaps"
reinstall_snaps "${SNAP_LIST[@]}"

print_header "Setting up rosbot snap for ROSbot $configuration"
/var/snap/rosbot/common/post_install.sh
snap set rosbot driver.robot-model=$ROBOT_MODEL
rosbot.flash

print_header "Setting up DepthAI snap"
snap connect husarion-depthai:shm-plug husarion-depthai:shm-slot
snap set husarion-depthai driver.parent-frame=camera_mount_link

print_header "Setting up RPLIDAR snap"
snap connect husarion-rplidar:shm-plug husarion-rplidar:shm-slot
if [[ $configuration == "3" ]]; then
    snap set husarion-rplidar configuration=c1
elif [[ $configuration == "3_pro" ]]; then
    snap set husarion-rplidar configuration=s2
else
    echo -e "\e[1mInvalid configuration for RPLIDAR.\e[0m"
fi

print_header "Setting up WebUI snap"
cp $LAYOUT_FILE /var/snap/husarion-webui/common/
snap set husarion-webui webui.layout=$ROBOT_MODEL

print_header "Setting up default DDS params on host (for root and $ORIG_USER)"
sudo -u "$ORIG_USER" /var/snap/rosbot/common/manage_ros_env.sh   # user‑side
/var/snap/rosbot/common/manage_ros_env.sh                        # root‑side

print_header "Start all snaps"
for snap in "${SNAP_LIST[@]}"; do
    "$snap".start
done

duration=$(( $(date +%s) - start_time ))
printf "Script completed in %02d:%02d (mm:ss)\n" $((duration/60)) $((duration%60))

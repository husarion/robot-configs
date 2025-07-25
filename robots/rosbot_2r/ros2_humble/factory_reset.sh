#!/bin/bash
set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP_LIST=(rosbot husarion-astra husarion-rplidar husarion-webui)
ROBOT_MODEL=rosbot
LAYOUT_FILE="$SCRIPT_DIR/foxglove-rosbot.json"

# ─── force root execution and remember the caller ──────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "Please start this script with: sudo $0" >&2
    exit 1
fi
ORIG_USER="${SUDO_USER:-root}"   # the login that invoked sudo

# Source
if [ -f "$SCRIPT_DIR/../../helpers.sh" ]; then
    source "$SCRIPT_DIR/../../helpers.sh" # Working inside repo
else
    source "$SCRIPT_DIR/helpers.sh" # Working on Husarion OS after setup_robot_configuration
fi

# Main
start_time=$(date +%s)

print_header "Reinstall snaps"
reinstall_snaps "${SNAP_LIST[@]}"

print_header "Setting up ROSbot snap"
/var/snap/rosbot/common/post_install.sh
snap set rosbot driver.robot-model=$ROBOT_MODEL
rosbot.flash

print_header "Setting up Astra snap"
snap connect husarion-astra:shm-plug husarion-astra:shm-slot
snap set husarion-astra driver.name=camera

print_header "Setting up RPLIDAR snap"
snap connect husarion-rplidar:shm-plug husarion-rplidar:shm-slot
snap set husarion-rplidar configuration=a2m12

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

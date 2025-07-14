#!/bin/bash
set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP_LIST=(rosbot husarion-astra husarion-rplidar husarion-webui)
ROBOT_MODEL=rosbot
LAYOUT_FILE="$SCRIPT_DIR/foxglove-rosbot.json"

# Source
if [ -f "$SCRIPT_DIR/../../helpers.sh" ]; then
    source "$SCRIPT_DIR/../../helpers.sh" # Working inside repo
else
    source "$SCRIPT_DIR/helpers.sh" # Working on Husarion OS after setup_robot_configuration
fi

# Main
start_time=$(date +%s)

check_user

print_header "Reinstall snaps"
reinstall_snaps "${SNAP_LIST[@]}"

print_header "Setting up ROSbot snap"
sudo /var/snap/rosbot/common/post_install.sh
sudo snap set rosbot driver.robot-model=$ROBOT_MODEL
sudo rosbot.flash

print_header "Setting up Astra snap"
sudo snap connect husarion-astra:shm-plug husarion-astra:shm-slot
sudo snap set husarion-astra driver.name=camera

print_header "Setting up RPLIDAR snap"
sudo snap connect husarion-rplidar:shm-plug husarion-rplidar:shm-slot
sudo snap set husarion-rplidar configuration=a3

print_header "Setting up WebUI snap"
sudo cp $LAYOUT_FILE /var/snap/husarion-webui/common/
sudo snap set husarion-webui webui.layout=$ROBOT_MODEL

print_header "Setting up default DDS params on host"
/var/snap/rosbot/common/manage_ros_env.sh
sudo /var/snap/rosbot/common/manage_ros_env.sh

print_header "Start all snaps"
for snap in "${SNAP_LIST[@]}"; do
    sudo "$snap".start
done

duration=$(( $(date +%s) - start_time ))
printf "Script completed in %02d:%02d (mm:ss)\n" $((duration/60)) $((duration%60))

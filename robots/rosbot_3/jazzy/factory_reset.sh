#!/bin/bash
set -e

# Source
if [ -f "/home/husarion/helpers.sh" ]; then
    source "/home/husarion/helpers.sh"
    source "/home/husarion/.robot_env"
else
    echo "This script should be running from /home/husarion directory. Please run setup_robot_configuration to copy specific robot files."
fi

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP_LIST=(rosbot husarion-depthai husarion-rplidar husarion-webui)
ROBOT_MODEL=rosbot
LAYOUT_FILE="$SCRIPT_DIR/foxglove-rosbot.json"

# Main
start_time=$(date +%s)

check_user

print_header "Reinstall snaps"
reinstall_snaps "$SNAP_VERSION" "${SNAP_LIST[@]}"

print_header "Setting up ROSbot snap"
sudo /var/snap/rosbot/common/post_install.sh
sudo snap set rosbot driver.robot-model=$ROBOT_MODEL
sudo rosbot.flash

print_header "Setting up DepthAI snap"
sudo snap connect husarion-depthai:shm-plug husarion-depthai:shm-slot
sudo snap set husarion-depthai driver.parent-frame=camera_mount_link

print_header "Setting up RPLIDAR snap"
sudo snap connect husarion-rplidar:shm-plug husarion-rplidar:shm-slot
sudo snap set husarion-rplidar configuration=s2

print_header "Setting up WebUI snap"
sudo cp $LAYOUT_FILE /var/snap/husarion-webui/common/
sudo snap set husarion-webui webui.layout=$ROBOT_MODEL

print_header "Setting up default DDS params on host"
sudo /var/snap/rosbot/common/manage_ros_env.sh

print_header "Start all snaps"
for snap in "${SNAP_LIST[@]}"; do
    sudo "$snap".start
done

duration=$(( $(date +%s) - start_time ))
printf "Script completed in %02d:%02d (mm:ss)\n" $((duration/60)) $((duration%60))

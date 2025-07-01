#!/bin/bash
set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP_LIST=(rosbot husarion-webui)
ADDITIONAL_SNAP_LIST=(husarion-depthai husarion-rplidar)
ROS_DISTRO=${ROS_DISTRO:-humble}
ROBOT_MODEL=rosbot-xl
LAYOUT_FILE="$SCRIPT_DIR/foxglove-rosbot-xl.json"

# Source
if [ -f "$SCRIPT_DIR/../../helpers.sh" ]; then
    source "$SCRIPT_DIR/../../helpers.sh" # Working inside repo
else
    source "$SCRIPT_DIR/helpers.sh" # Working on Husarion OS after setup_robot_configuration
fi

# Main
start_time=$(date +%s)

check_user

ARE_ADDITIONAL_SNAPS=false
if ask_to_install_snaps "${ADDITIONAL_SNAP_LIST[@]}"; then
    SNAP_LIST+=("${ADDITIONAL_SNAP_LIST[@]}")
    ARE_ADDITIONAL_SNAPS=true
fi

print_header "Reinstall snaps"
reinstall_snaps "${SNAP_LIST[@]}"

print_header "Setting up ROSbot snap"
sudo /var/snap/rosbot/common/post_install.sh
sudo snap set rosbot driver.robot-model=$ROBOT_MODEL
sudo rosbot.flash

if [ "$ARE_ADDITIONAL_SNAPS" = true ]; then
    print_header "Setting up DepthAI snap"
    sudo snap connect husarion-depthai:shm-plug husarion-depthai:shm-slot
    sudo snap set husarion-depthai driver.parent-frame=camera_mount_link

    print_header "Setting up RPLIDAR snap"
    sudo snap connect husarion-rplidar:shm-plug husarion-rplidar:shm-slot
    sudo snap set husarion-rplidar configuration=s3
fi

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

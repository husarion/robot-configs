#!/bin/bash
set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP_LIST=(rosbot husarion-webui)
ROS_DISTRO=${ROS_DISTRO:-jazzy}
ROBOT_MODEL=rosbot-xl
LAYOUT_FILE="$SCRIPT_DIR/foxglove-rosbot-xl.json"
VALID_CONFIGURATION=("basic" "telepresence" "autonomy" "manipulation" "manipulation-pro")

# Source
if [ -f "$SCRIPT_DIR/../../helpers.sh" ]; then
    source "$SCRIPT_DIR/../../helpers.sh" # Working inside repo
else
    source "$SCRIPT_DIR/helpers.sh" # Working on Husarion OS after setup_robot_configuration
fi

# Main
start_time=$(date +%s)

check_user

select configuration in "${VALID_CONFIGURATION[@]}"; do
    if [[ " ${VALID_CONFIGURATION[*]} " == *" $configuration "* ]]; then
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

case $configuration in
    "basic")
        ;;
    "telepresence")
        SNAP_LIST+=(husarion-depthai)
        ;;
    "autonomy")
        SNAP_LIST+=(husarion-depthai husarion-rplidar)
        ;;
    "manipulation")
        SNAP_LIST+=(husarion-rplidar)
        ;;
    "manipulation-pro")
        SNAP_LIST+=(husarion-rplidar)
        ;;
    *)
        echo "Invalid configuration selected. Exiting."
        exit 1
        ;;
esac

print_header "Reinstall snaps"
reinstall_snaps "${SNAP_LIST[@]}"

print_header "Setting up ROSbot snap $configuration"
sudo /var/snap/rosbot/common/post_install.sh
sudo snap set rosbot driver.robot-model=$ROBOT_MODEL
sudo snap set rosbot driver.configuration=$configuration
sudo rosbot.flash

if [[ " ${SNAP_LIST[@]} " =~ " husarion-depthai " ]]; then
    print_header "Setting up DepthAI snap"
    sudo snap connect husarion-depthai:shm-plug husarion-depthai:shm-slot
    sudo snap set husarion-depthai driver.parent-frame=camera_mount_link
fi

if [[ " ${SNAP_LIST[@]} " =~ " husarion-rplidar " ]]; then
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

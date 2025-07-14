#!/bin/bash
set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP_LIST=(rosbot husarion-webui)
ROBOT_MODEL=rosbot-xl
LAYOUT_FILE="$SCRIPT_DIR/foxglove-rosbot-xl.json"
VALID_CONFIGURATIONS=("basic" "telepresence" "autonomy" "manipulation" "manipulation-pro")

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

check_user

configuration="$1"

if [[ -n "$configuration" ]]; then
    if [[ " ${VALID_CONFIGURATIONS[@]} " =~ " ${configuration} " ]]; then
        set_robot_env "ROBOT_CONFIGURATION" "$configuration"
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

case $configuration in
    "telepresence")
        SNAP_LIST+=(husarion-depthai)
        ;;
    "autonomy")
        SNAP_LIST+=(husarion-depthai husarion-rplidar)
        ;;
    "manipulation"|"manipulation-pro")
        SNAP_LIST+=(husarion-rplidar)
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
    sed -i 's|^# sudo husarion-depthai.start|sudo husarion-depthai.start|' ./ros_driver_start.sh
    sed -i 's|^# sudo husarion-depthai.stop|sudo husarion-depthai.stop|' ./ros_driver_stop.sh
fi

if [[ " ${SNAP_LIST[@]} " =~ " husarion-rplidar " ]]; then
    print_header "Setting up RPLIDAR snap"
    sudo snap connect husarion-rplidar:shm-plug husarion-rplidar:shm-slot
    sudo snap set husarion-rplidar configuration=s3
    sed -i 's|^# sudo husarion-rplidar.start|sudo husarion-rplidar.start|' ./ros_driver_start.sh
    sed -i 's|^# sudo husarion-rplidar.stop|sudo husarion-rplidar.stop|' ./ros_driver_stop.sh
fi

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

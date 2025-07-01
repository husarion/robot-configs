#!/bin/bash
set -e

# Check if the script is being run as a normal user
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: This script must be run as a normal user."
    exit 1
fi

SNAP_LIST=(
    rosbot-xl
    husarion-webui
)

ROS_DISTRO=${ROS_DISTRO:-humble}
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

start_time=$(date +%s)

if [ -d "/var/snap/rosbot-xl" ]; then
    /var/snap/rosbot-xl/common/manage_ros_env.sh remove
    sudo /var/snap/rosbot-xl/common/manage_ros_env.sh remove
fi

for snap in "${SNAP_LIST[@]}"; do
    echo "---------------------------------------"
    echo "removing the \"$snap\" snap"
    sudo snap remove "$snap"
done

for snap in "${SNAP_LIST[@]}"; do
    echo "---------------------------------------"
    echo "Installing the \"$snap\" snap (ROS 2 ${ROS_DISTRO}/stable)"
    sudo snap install "$snap" --channel="$ROS_DISTRO"/stable
    sudo "$snap".stop
    sudo snap set "$snap" \
        ros.transport=udp-lo \
        ros.localhost-only='' \
        ros.domain-id=0 \
        ros.namespace=''

    # disable auto-refresh (auto update)
    # sudo snap refresh --hold=forever $snap
done

echo "---------------------------------------"
echo "Setting up the \"rosbot-xl\" snap"
sudo /var/snap/rosbot-xl/common/post_install.sh
sudo snap set rosbot-xl driver.mecanum=True
sudo rosbot-xl.flash

echo "---------------------------------------"
echo "Setting up the \"husarion-webui\" snap"
sudo cp $SCRIPT_DIR/foxglove-rosbot-xl.json /var/snap/husarion-webui/common/
sudo snap set husarion-webui webui.layout=rosbot-xl

echo "---------------------------------------"
echo "Default DDS params on host"
/var/snap/rosbot-xl/common/manage_ros_env.sh
sudo /var/snap/rosbot-xl/common/manage_ros_env.sh

# # Remove specific snaps
# SNAP_LIST=( ${SNAP_LIST[@]/husarion-rplidar} )
# SNAP_LIST=( ${SNAP_LIST[@]/husarion-depthai} )
echo "---------------------------------------"
echo "Starting the following snaps: ${SNAP_LIST[*]}"

for snap in "${SNAP_LIST[@]}"; do
    sudo "$snap".start
    # sudo "$snap".restart
done

end_time=$(date +%s)
duration=$(( end_time - start_time ))

hours=$(( duration / 3600 ))
minutes=$(( (duration % 3600) / 60 ))
seconds=$(( duration % 60 ))

printf "Script completed in %02d:%02d:%02d (hh:mm:ss)\n" $hours $minutes $seconds

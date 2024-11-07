#!/bin/bash

# Check if the script is being run as a normal user
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: This script must be run as a normal user."
    exit 1
fi

SNAP_LIST=(
    rosbot
    husarion-rplidar
    husarion-depthai
    husarion-webui
)

for snap in "${SNAP_LIST[@]}"; do
    echo "---------------------------------------"
    echo "removing the \"$snap\" snap"
    sudo snap remove "$snap" 
done

echo "---------------------------------------"
echo "Setting up the \"rosbot\" snap"
sudo snap install rosbot --channel=jazzy
sudo /var/snap/rosbot/common/post_install.sh
sleep 2
sudo rosbot.flash

echo "---------------------------------------"
echo "Setting up the \"husarion-rplidar\" snap"
sudo snap install husarion-rplidar --channel=jazzy
sudo snap set husarion-rplidar configuration=s2

echo "---------------------------------------"
echo "Setting up the \"husarion-depthai\" snap"
sudo snap install husarion-depthai --channel=jazzy

echo "---------------------------------------"
echo "Setting up the \"husarion-webui\" snap"
sudo snap install husarion-webui --channel=jazzy
sudo snap set husarion-webui webui.layout=rosbot3

echo "---------------------------------------"
echo "Default DDS params"
for snap in "${SNAP_LIST[@]}"; do
    echo "---------------------------------------"
    sudo snap set "$snap" ros.transport=udp-lo
    sudo snap set "$snap" ros.localhost-only=''
    sudo snap set "$snap" ros.domain-id=0
    sudo snap set "$snap" ros.namespace=''
done

echo "---------------------------------------"
echo "Default DDS params on host"
/var/snap/rosbot/common/manage_ros_env.sh

sudo rosbot.restart
sudo husarion-webui.start

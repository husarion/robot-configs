#!/bin/bash

# If a particular robot requires any extra custom configuration steps, they should be included in this file.

CONFIG_FILES_PATH="/etc/husarion/robot_configs/panther"

# Time server config
cp ${CONFIG_FILES_PATH}/files/chrony.conf /etc/chrony/chrony.conf
cp ${CONFIG_FILES_PATH}/files/chrony.service /lib/systemd/system/chrony.service
cp ${CONFIG_FILES_PATH}/files/hwclock-set /lib/udev/hwclock-set

# Disable dhcp-server
sudo service isc-dhcp-server stop
sudo systemctl disable isc-dhcp-server
sudo systemctl daemon-reload

# Setup envs
echo "ROS_IP=10.15.20.3" >> /etc/environment
echo "ROS_MASTER_URI=http://10.15.20.2:11311" >> /etc/environment

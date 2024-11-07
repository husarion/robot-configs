#!/bin/bash

# If a particular robot requires any extra custom configuration steps, they should be included in this file.

CONFIG_FILES_PATH="/etc/husarion/robot_configs/panther"

# Time server config
cp ${CONFIG_FILES_PATH}/files/chrony.conf /etc/chrony/chrony.conf
cp ${CONFIG_FILES_PATH}/files/chrony.service /lib/systemd/system/chrony.service
cp ${CONFIG_FILES_PATH}/files/hwclock-set /lib/udev/hwclock-set

# Set default rmw as cyclonedds
echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc
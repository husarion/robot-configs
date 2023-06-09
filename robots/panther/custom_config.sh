#!/bin/bash

# If a particular robot requires any extra custom configuration steps, they should be included in this file.

CONFIG_FILES_PATH="/etc/husarion/robot_configs/panther"

# Time server config
sudo apt install chrony

cp ${CONFIG_FILES_PATH}/files/chrony.conf /etc/chrony/chrony.conf
cp ${CONFIG_FILES_PATH}/files/chrony.service /lib/systemd/system/chrony.service
cp ${CONFIG_FILES_PATH}/files/hwclock-set /lib/udev/hwclock-set

# Build panther_msgs pkg
mkdir -p /home/husarion/husarion_ws
cd /home/husarion/husarion_ws
git clone https://github.com/husarion/panther_msgs.git ./src/panther_msgs -b ros1
source /opt/ros/noetic/setup.bash
catkin_make

echo "source /opt/ros/noetic/setup.bash" >> /home/husarion/.bashrc
echo "source ~/husarion_ws/devel/setup.bash" >> /home/husarion/.bashrc

# Setup envs
echo "ROS_IP=10.15.20.3" >> /etc/environment
echo "ROS_MASTER_URI=http://10.15.20.2:11311" >> /etc/environment
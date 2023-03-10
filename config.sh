#!/bin/bash

# Check if running with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Parse command line arguments
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 ROBOT_MODEL ROS_VERSION"
    exit 1
fi

robot_model="$1"
ros_version="$2"

# Check if the robot model is valid
if [[ "$robot_model" != "rosbot" && "$robot_model" != "rosbot-xl" ]]; then
    echo "Invalid robot model: $robot_model"
    exit 1
fi

# Check if the ROS version is valid
if [[ "$ros_version" != "ros-noetic" && "$ros_version" != "ros2-humble" && "$ros_version" != "vulcanexus-humble" ]]; then
    echo "Invalid ROS version: $ros_version"
    exit 1
fi

cp -r ./${robot_model}/${ros_version}/* /home/husarion
dpkg -i ./${robot_model}/motd-$(uname -m).deb
cp ./${robot_model}/netplan.yaml /etc/netplan/01-network-manager-all.yaml


# Print success message
echo "Configuration files copied successfully for robot model $robot_model and ROS version $ros_version"

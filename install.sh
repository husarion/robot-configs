#!/bin/bash

# Check if running with root privileges
# If the effective user ID is not zero, print an error message and exit with status 1
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

MY_PATH=$(dirname $(readlink -f "$0"))

echo "Installing configs for:"

# Traverse the robots directory and copy each custom_config.sh file to /usr/lib/husarion with "subfolder.sh" name
for file in $(find ${MY_PATH}/robots -name "custom_config.sh")
do
    # Get the parent directory name and replace '/' with '-'
    dirname=$(basename $(dirname "$file"))

    # Print the directory name for debugging purposes
    echo $dirname

    # Create the destination directory if it doesn't exist
    mkdir -p /usr/lib/husarion

    # Copy the file to /usr/lib/husarion with "subfolder.sh" name
    cp "$file" "/usr/lib/husarion/custom_config_${dirname}.sh"
done

# Copy the setup_robot_configuration script to /usr/local/sbin/
cp $MY_PATH/setup_robot_configuration /usr/local/sbin/

# Copy all files in the robots directory to /etc/husarion/robot-configs/
mkdir -p /etc/husarion/robot_configs/
cp -rp $MY_PATH/robots/* /etc/husarion/robot_configs/

# Traverse the robot-configs directory and remove all custom_config.sh files
for file in $(find /etc/husarion/robot_configs/ -name "custom_config.sh")
do
    rm -rf $file
done

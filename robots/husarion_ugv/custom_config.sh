#!/bin/bash

# If a particular robot requires any extra custom configuration steps, they should be included in this file.

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# Time server config
cp ${SCRIPT_DIR}/files/chrony.conf /etc/chrony/chrony.conf
cp ${SCRIPT_DIR}/files/chrony.service /lib/systemd/system/chrony.service
cp ${SCRIPT_DIR}/files/hwclock-set /lib/udev/hwclock-set

# Disable dhcp-server
sudo service isc-dhcp-server stop
sudo systemctl disable isc-dhcp-server
sudo systemctl daemon-reload

# Disable cloud-init network config
sudo rm -rf /etc/netplan/50-cloud-init.yaml 
sudo echo 'network: {config: disabled}' > /etc/netplan/99-disable-network-config.cfg
sudo chmod 600 /etc/netplan/99-disable-network-config.cfg

# Udev rules for PAD02
sudo echo 'ACTION=="add", ,ATTRS{interface}=="PAD02 Dongle", SYMLINK+="ttyUSBPAD"' > /etc/udev/rules.d/99-pad02.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# ROS config
if [ "$ROS_DISTRO" == "noetic" ]; then
  echo "ROS_IP=10.15.20.3" >> /etc/environment
  echo "ROS_MASTER_URI=http://10.15.20.2:11311" >> /etc/environment
else
  # Set default rmw as cyclonedds
  echo "RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> /etc/environment
fi

# Install husarion-shutdown snap
if ! ping -c 1 "8.8.8.8" &> /dev/null; then
  echo "No internet connection. Installing husarion-shutdown snap from local files."
  echo "This version of the snap is not guaranteed to be the latest version."
  echo "Please connect to the internet and check for updates with 'sudo snap refresh'."
  sudo snap ack ${SCRIPT_DIR}/files/snaps/core24*.assert
  sudo snap install ${SCRIPT_DIR}/files/snaps/core24*.snap
  sudo snap ack ${SCRIPT_DIR}/files/snaps/husarion-shutdown*.assert
  sudo snap install ${SCRIPT_DIR}/files/snaps/husarion-shutdown*.snap
  sudo husarion-shutdown.start
else
  sudo snap install husarion-shutdown
  sudo husarion-shutdown.start
fi

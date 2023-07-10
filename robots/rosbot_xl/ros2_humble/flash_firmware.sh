#!/bin/bash

# Get the current user
CURRENT_USER=$(whoami)

# Check if the current user is "husarion"
if [ "$CURRENT_USER" != "husarion" ]; then
  echo "This script can only be run by the user 'husarion'."
  exit 1
fi

# Define the Docker image
DOCKER_IMAGE="husarion/rosbot-xl:humble"

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${GREEN}[1/4]\r\nInitiating firmware flash on the ROSbot XL Digital Board. We're using the Docker image ${BOLD}$DOCKER_IMAGE${NC}${GREEN} for this process...${NC}"

# Check if the Docker image exists
if ! docker image inspect $DOCKER_IMAGE >/dev/null 2>&1; then
  echo -e "${YELLOW}${BOLD}$DOCKER_IMAGE${NC}${YELLOW} not found. Pulling...${NC}"
  docker pull $DOCKER_IMAGE
fi
echo -e "${GREEN}done${NC}"

# Stop the Docker containers if they're running
echo -e "\r\n${GREEN}[2/4]\r\nStop ${BOLD}rosbot-xl${NC}${GREEN} and ${BOLD}microros${NC}${GREEN} Docker containers if they're running ${NC}"

# Define the Docker containers
CONTAINERS=("rosbot-xl" "microros")

# Loop through each container and stop it if it exists and is running
for CONTAINER in "${CONTAINERS[@]}"; do
    CONTAINER_ID=$(docker ps -q -f name=$CONTAINER)
    if [ ! -z "$CONTAINER_ID" ]; then
        echo "Stopping container $CONTAINER..."
        docker stop $CONTAINER
    fi
done

# Checking if /dev/ttyUSBDB exists
DEVICE="/dev/ttyUSBDB"

# Print a status update message, with the device name in bold
echo -e "\r\n${GREEN}[3/4]\r\nChecking if the Digital Board (${BOLD}$DEVICE${NC}${GREEN}) is connected...${NC}"

# Use an if statement to check if the device file exists
if [ -e "$DEVICE" ]; then
    # If the device file exists, print a confirmation message
    echo -e "${GREEN}The device ${BOLD}$DEVICE${NC}${GREEN} is successfully detected.${NC}"
else
    # If the device file doesn't exist, print an error message and exit the script
    echo -e "${RED}The device ${BOLD}$DEVICE${NC}${RED} cannot be detected. Please connect the Digital Board to a USB port.${NC}"
    exit 1
fi

# Flashing

echo -e "\r\n${GREEN}[4/4]\r\nFlashing the firmware...${NC}"

docker run --rm -it --privileged \
--mount type=bind,source=/dev/ttyUSBDB,target=/dev/ttyUSBDB \
$DOCKER_IMAGE \
flash-firmware.py -p /dev/ttyUSBDB

echo -e "${GREEN}done${NC}"
#!/bin/bash

# Get the current user
CURRENT_USER=$(whoami)

# Check if the current user is "husarion"
if [ "$CURRENT_USER" != "husarion" ]; then
  echo "This script can only be run by the user 'husarion'."
  exit 1
fi

# Define the Docker image
DOCKER_IMAGE="husarion/rosbot:humble"

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${GREEN}[1/3]\r\nInitiating firmware flash on the ROSbot's STM32F4 microcontroller. We're using the Docker image ${BOLD}$DOCKER_IMAGE${NC}${GREEN} for this process...${NC}"

# Check if the Docker image exists
if ! docker image inspect $DOCKER_IMAGE >/dev/null 2>&1; then
  echo -e "${YELLOW}${BOLD}$DOCKER_IMAGE${NC}${YELLOW} not found. Pulling...${NC}"
  docker pull $DOCKER_IMAGE
fi
echo -e "${GREEN}done${NC}"

# Stop the Docker containers if they're running
echo -e "\r\n${GREEN}[2/3]\r\nStop ${BOLD}rosbot${NC}${GREEN} Docker containers if it is running ${NC}"

docker stop rosbot

# Flashing

echo -e "\r\n${GREEN}[3/3]\r\nFlashing the firmware...${NC}"

docker run --rm -it --privileged \
$DOCKER_IMAGE \
/flash-firmware.py /root/firmware.bin

echo -e "${GREEN}done${NC}"
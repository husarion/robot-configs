#!/bin/bash
set -euo pipefail

# Get the current user
CURRENT_USER=$(whoami)

# Check if the current user is "husarion"
if [ "$CURRENT_USER" != "husarion" ]; then
  echo "This script can only be run by the user 'husarion'."
  exit 1
fi

# Define the Docker image
DOCKER_IMAGE=$(yq .services.rosbot.image $(dirname "$0")/compose.yaml)

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${GREEN}[1/2]\r\nInitiating firmware flash on the ROSbot's STM32F4 microcontroller. We're using the Docker image ${BOLD}$DOCKER_IMAGE${NC}${GREEN} for this process...${NC}"

# Check if the Docker image exists
if ! docker image inspect $DOCKER_IMAGE >/dev/null 2>&1; then
  echo -e "${YELLOW}${BOLD}$DOCKER_IMAGE${NC}${YELLOW} not found. Pulling...${NC}"
  docker pull $DOCKER_IMAGE
fi
echo -e "${GREEN}done${NC}"

# Get the list of running container IDs
CONTAINER_IDS=$(docker ps -q)

# Check if the variable is not empty
if [ -n "$CONTAINER_IDS" ]; then
    # If there are running containers, stop them
    docker stop $CONTAINER_IDS
else
    # If there are no running containers, do nothing
    echo "No running containers to stop."
fi

# Flashing

echo -e "\r\n${GREEN}[2/2]\r\nFlashing the firmware...${NC}"

docker run --rm -it --privileged \
$DOCKER_IMAGE \
ros2 run rosbot_utils flash_firmware

echo -e "${GREEN}done${NC}"
#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Stop the Docker containers if they're running
echo -e "${GREEN}[1/1]\tStopping ROS 2 driver ${NC}"

# Define the docker-compose file
COMPOSE_FILE="/home/husarion/compose.yaml"
docker compose -f $COMPOSE_FILE down
ros2 daemon stop

echo -e "\t${GREEN}done.${NC}"

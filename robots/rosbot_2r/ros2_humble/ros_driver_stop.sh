#!/bin/bash
set -euo pipefail

# Get the current user
CURRENT_USER=$(whoami)

# Check if the current user is "husarion"
if [ "$CURRENT_USER" != "husarion" ]; then
  echo "This script can only be run by the user 'husarion'."
  exit 1
fi

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Stop the Docker containers if they're running
echo -e "${GREEN}[1/1]\r\nStopping ROS 2 driver ${NC}"

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define the docker-compose file
COMPOSE_FILE="$SCRIPT_DIR/compose.yaml"

docker compose -f $COMPOSE_FILE down
ros2 daemon stop

echo -e "${GREEN}done.${NC}"

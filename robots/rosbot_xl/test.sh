#!/bin/bash

SNAP_LIST=(
    rosbot
    husarion-rplidar
    husarion-depthai
    husarion-webui
)

SNAP_LIST=( ${SNAP_LIST[@]/rosbot} )

for snap in "${SNAP_LIST[@]}"; do
    echo "Installing the \"$snap\""
done
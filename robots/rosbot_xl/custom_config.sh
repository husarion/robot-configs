#!/bin/bash

# If a particular robot requires any extra custom configuration steps, they should be included in this file.

echo "Installing ROSbot XL snap"

if [ "$ROS_DISTRO" == "jazzy" ]; then
    sudo snap install rosbot-xl --channel=jazzy
else
    sudo snap install rosbot-xl
fi

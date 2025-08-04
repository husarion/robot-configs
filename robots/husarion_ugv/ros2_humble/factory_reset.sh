#!/bin/bash
set -e

# Check if the script is being run as a normal user
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: This script must be run as a normal user."
    exit 1
fi

SNAP_LIST=(
    husarion-shutdown
)

start_time=$(date +%s)

for snap in "${SNAP_LIST[@]}"; do
    echo "---------------------------------------"
    echo "removing the \"$snap\" snap"
    sudo snap remove "$snap"
done

for snap in "${SNAP_LIST[@]}"; do
    echo "---------------------------------------"
    echo "Installing the \"$snap\" snap"
    sudo snap install "$snap"
    sudo "$snap".stop
done

echo "---------------------------------------"
echo "Start all snap"

for snap in "${SNAP_LIST[@]}"; do
    sudo "$snap".start
done

echo "---------------------------------------"
echo "Installing Husarion UGV Configurator..."

rm -rf ~/husarion_ugv_configurator
git clone https://github.com/husarion/husarion_ugv_configurator.git ~/husarion_ugv_configurator

cd ~/husarion_ugv_configurator
just install

end_time=$(date +%s)
duration=$(( end_time - start_time ))

hours=$(( duration / 3600 ))
minutes=$(( (duration % 3600) / 60 ))
seconds=$(( duration % 60 ))

printf "Script completed in %02d:%02d:%02d (hh:mm:ss)\n" $hours $minutes $seconds

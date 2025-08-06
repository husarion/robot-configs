#!/bin/bash
set -e

# ─── force root execution and remember the caller ──────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "Please start this script with: sudo $0" >&2
    exit 1
fi
ORIG_USER="${SUDO_USER:-root}"   # the login that invoked sudo

SNAP_LIST=(
    husarion-shutdown
)

start_time=$(date +%s)

for snap in "${SNAP_LIST[@]}"; do
    echo "---------------------------------------"
    echo "removing the \"$snap\" snap"
    snap remove "$snap"
done

for snap in "${SNAP_LIST[@]}"; do
    echo "---------------------------------------"
    echo "Installing the \"$snap\" snap"
    snap install "$snap"
    "$snap".stop
done

echo "---------------------------------------"
echo "Start all snap"

for snap in "${SNAP_LIST[@]}"; do
    "$snap".start
done

echo "---------------------------------------"
echo "Installing Husarion UGV Configurator..."

rm -rf /home/husarion/husarion_ugv_configurator
git clone https://github.com/husarion/husarion_ugv_configurator.git /home/husarion/husarion_ugv_configurator

# Change owner of the configurator directory to the husarion user
chown -R husarion:husarion /home/husarion/husarion_ugv_configurator

cd /home/husarion/husarion_ugv_configurator
just install

end_time=$(date +%s)
duration=$(( end_time - start_time ))

hours=$(( duration / 3600 ))
minutes=$(( (duration % 3600) / 60 ))
seconds=$(( duration % 60 ))

printf "Script completed in %02d:%02d:%02d (hh:mm:ss)\n" $hours $minutes $seconds

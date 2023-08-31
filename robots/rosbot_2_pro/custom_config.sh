#!/bin/bash

# If a particular robot requires any extra custom configuration steps, they should be included in this file.

echo "enable reset MCU service"

cp /etc/husarion/robot_configs/_rosbot_2_reset_mcu/reset-mcu.py /usr/local/sbin/reset-mcu.py
cp /etc/husarion/robot_configs/_rosbot_2_reset_mcu/reset-mcu.service /etc/systemd/system/reset-mcu.service

systemctl enable reset-mcu.service
systemctl start reset-mcu.service

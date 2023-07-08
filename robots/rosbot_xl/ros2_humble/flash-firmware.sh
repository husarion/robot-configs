#!/bin/bash

docker stop rosbot-xl microros || true && \

docker run --rm -it --privileged \
--mount type=bind,source=/dev/ttyUSBDB,target=/dev/ttyUSBDB \
husarion/rosbot-xl:humble \
flash-firmware.py -p /dev/ttyUSBDB
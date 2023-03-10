# robot-configs

Basic Husarion robots configs for Husarion OS 

## Installing

```bash
sudo su
cd /etc
git clone https://github.com/husarion/robot-configs
```

## Using

```bash
sudo su

# ========================
# Select a robot model
# ========================

export ROBOT_MODEL=rosbot-xl
#export ROBOT_MODEL=rosbot

# ========================
# Select a ROS version
# ========================

export ROS_VERSION=ros2-humble
# export ROS_VERSION=ros-noetic
# export ROS_VERSION=vulanexus-humble

# ========================
# Run the configuration
# ========================

/etc/robot-configs/config.sh $ROBOT_MODEL $ROS_VERSION
```
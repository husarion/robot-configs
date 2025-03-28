# robot-configs

Basic Husarion robots configs for Husarion OS

## Installing

```bash
cd /opt
sudo git clone https://github.com/husarion/robot-configs
sudo echo "PATH=$PATH:/opt/robot-configs" > ~/.bashrc
```

## Using

```bash
source ~/.bashrc

# ========================
# Select a robot model
# ========================

export ROBOT_MODEL=rosbot_xl
#export ROBOT_MODEL=rosbot_2r

# ========================
# Select a ROS version
# ========================

export ROS_VERSION=ros2_humble
# export ROS_VERSION=ros_noetic
# export ROS_VERSION=vulcanexus_humble

# ========================
# Run the configuration
# ========================

sudo setup_robot_configuration $ROBOT_MODEL $ROS_VERSION
```

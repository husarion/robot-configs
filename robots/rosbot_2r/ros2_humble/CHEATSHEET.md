## Print ROS envs

```
printenv | grep ROS
```

## Configs

### Default

```
./ros_driver_stop.sh
export ROS_DOMAIN_ID=12
unset ROS_LOCALHOST_ONLY
./ros_driver_start.sh
```

### Localhost Only

```
./ros_driver_stop.sh
unset ROS_DOMAIN_ID
export ROS_LOCALHOST_ONLY=1
./ros_driver_start.sh
```

### Topic filtering over Husarnet

```
./ros_driver_stop.sh
unset ROS_DOMAIN_ID
export ROS_LOCALHOST_ONLY=1
./ros_driver_start.sh
./ros_driver_start.sh ros2router
```

Modify `filter.yaml` file in run-time to change allow- and block-list.
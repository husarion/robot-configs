# robot-configs

Basic Husarion robots configs for Husarion OS

## Installing

```bash
cd /opt
sudo git clone https://github.com/husarion/robot-configs
sudo ln -s /opt/robot-configs/setup_robot_configuration /usr/local/bin/setup_robot_configuration
```

## Using

1. Prepare the OS and copy specific configuration files for the robot.

    ```bash
    source ~/.bashrc
    sudo setup_robot_configuration <robot_model> [ros_version]
    ```

    | Arguments         | Values                                   |
    | :--------------- | :------------------------------------------------- |
    | `robot_model`    | `rosbot_xl`, `rosbot_3`, `rosbot_2r`, `rosbot_2_pro`, `panther`, `lynx`, `husarion_ugv` |
    | `ros_version`    | `jazzy`, `humble`, `noetic` |

2. Default robot set up.

```bash
~/factory_reset.sh
```

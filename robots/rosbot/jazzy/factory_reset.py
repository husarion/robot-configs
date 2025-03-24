import os
import sys
import time

bold = "\033[1m"
reset = "\033[0m"

def is_root():
    return os.geteuid() == 0

def prompt_user(prompt, options):
    while True:
        user_input = input(f"{bold}{prompt}{reset} ({'/'.join(options)}): ").strip()
        if user_input in options:
            return user_input
        print(f"Invalid selection: {user_input}. Please choose one of: {', '.join(options)}")

def exec(command):
    os.system(command)

# {robot_model: {robot_configuration: {snap_name: snap_configuration}}}
robot_configurations = {
    "rosbot": {
        "3": {
            "husarion-depthai": [],
            "husarion-rplidar": ["configuration=c1"],
            "husarion-webui": ["webui.layout=rosbot"]
        },
        "3 PRO": {
            "husarion-depthai": [],
            "husarion-rplidar": ["configuration=s2"],
            "husarion-webui": ["webui.layout=rosbot"]
        }
    },
    "rosbot_xl": {
        "basic": {
            "husarion-webui": ["webui.layout=rosbot_xl"]
        },
        "telepresence": {
            "husarion-depthai": [],
            "husarion-webui": ["webui.layout=rosbot_xl"]
        },
        "autonomy": {
            "husarion-depthai": [],
            "husarion-rplidar": ["configuration=s3"],
            "husarion-webui": ["webui.layout=rosbot_xl"]
        },
        "manipulation": {
            "husarion-rplidar": ["configuration=s3"],
            "husarion-webui": ["webui.layout=rosbot_xl"]
        },
        "manipulation_pro": {
            "husarion-rplidar": ["configuration=s3"],
            "husarion-webui": ["webui.layout=rosbot_xl"]
        }
    }
}


def main():
    if is_root():
        print("Error: This script must be run as a normal user.")
        sys.exit(1)

    # Check if environment variables are already set
    robot_model = os.getenv("ROBOT_MODEL_NAME")
    configuration_pkg = os.getenv("CONFIGURATION_PKG")

    if not robot_model or not configuration_pkg:
        robot_model = prompt_user("Specify ROSbot model", ["rosbot", "rosbot_xl"])
        configuration_pkg = prompt_user("Specify configuration package", robot_configurations[robot_model].keys())

        # Save the selected robot model and configuration package as environment variables
        os.system(f"echo 'export ROBOT_MODEL_NAME={robot_model}' >> ~/.bashrc")
        os.system(f"echo 'export CONFIGURATION_PKG={configuration_pkg}' >> ~/.bashrc")
        os.system("source ~/.bashrc")
    else:
        print(f"Using existing environment variables: ROBOT_MODEL={robot_model}, CONFIGURATION_PKG={configuration_pkg}")
    
    snap_list = ["rosbot"] + list(robot_configurations[robot_model][configuration_pkg].keys())
    ros_distro = os.getenv("ROS_DISTRO")
    if not ros_distro:
        print("Error: ROS_DISTRO environment variable is not set.")
        sys.exit(1)
    start_time = time.time()
    
    exec("/var/snap/rosbot/common/manage_ros_env.sh remove > /dev/null 2>&1")
    exec("sudo /var/snap/rosbot/common/manage_ros_env.sh remove > /dev/null 2>&1")
    
    for snap in snap_list:
        print(f"Removing the {bold}{snap}{reset} snap")
        exec(f"sudo snap remove --pruge {snap}")
    
    for snap in snap_list:
        print(f"Installing the {bold}{snap}{reset} snap (ROS 2 {ros_distro})")
        if snap == "rosbot":
            exec(f"sudo snap install {snap} --channel=jazzy/edge")
        else:
            exec(f"sudo snap install {snap} --channel={ros_distro}")
        exec(f"sudo {snap}.stop")
        exec(f"sudo snap set {snap} ros.transport=udp-lo ros.localhost-only='' ros.domain-id=0 ros.namespace='' ")
        exec(f"sudo snap connect {snap}:shm-plug {snap}:shm-slot")
        if snap == "husarion-depthai":
            exec("sudo snap set husarion-depthai driver.parent-frame=camera_mount_link")
        configurations = robot_configurations[robot_model][configuration_pkg].get(snap, [])
        for configuration in configurations:
            exec(f"sudo snap set {snap} {configuration}")


    print(f"Setting up the {bold}rosbot{reset} snap")
    exec("sudo /var/snap/rosbot/common/post_install.sh")
    exec("sudo rosbot.stop")
    time.sleep(2)
    exec("sudo rosbot.flash")
    
    print("Default DDS params on host")
    exec("/var/snap/rosbot/common/manage_ros_env.sh")
    exec("sudo /var/snap/rosbot/common/manage_ros_env.sh")
    
    print("Start all snaps")
    for snap in snap_list:
        exec(f"sudo {snap}.start")
    
    duration = int(time.time() - start_time)
    hours, remainder = divmod(duration, 3600)
    minutes, seconds = divmod(remainder, 60)
    print(f"Script completed in {hours:02}:{minutes:02}:{seconds:02} (hh:mm:ss)")
    
if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(1)
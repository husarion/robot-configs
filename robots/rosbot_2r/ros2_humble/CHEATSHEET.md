## Print ROS envs

```
printenv | grep ROS
```

## Configs

### Using `ROS_DOMAIN_ID`

```
./ros_driver_stop.sh
export ROS_DOMAIN_ID=12
unset ROS_LOCALHOST_ONLY
./ros_driver_start.sh
```

### Using `ROS_LOCALHOST_ONLY`

```
./ros_driver_stop.sh
unset ROS_DOMAIN_ID
export ROS_LOCALHOST_ONLY=1
./ros_driver_start.sh
```

### VPN only (with topic filtering)

### On ROSbot 2R

```
./ros_driver_stop.sh
unset ROS_DOMAIN_ID
export ROS_LOCALHOST_ONLY=1
./ros_driver_start.sh
./ros_driver_start.sh ros2router
```

Modify `filter.yaml` file in run-time to change allow- and block-list.

### On remote desktop

#### Option 1: `ros2router`

```
docker run \
--restart always \
--network host \
-e ROS_DISCOVERY_SERVER="rosbot2r:11811" \
-e DISCOVERY_SERVER_ID=2 \
husarnet/ros2router:1.2.0
```

#### Option 2: `ROS_DISCOVERY_SERVER` env

This option works with IPv6 address from FastDDS `v2.8.0`:
- ROS 2 Iron - contains FastDDS `v2.10.2`
- ROS 2 Humble - includes FastDDS `2.6.6`

```
export ROS_DISCOVERY_SERVER=rosbot2r:11811
ros2 daemon stop
```

> warning!
>
> This env runs FastDDS in a `CLIENT` (not `SUPER_CLIENT`) config, so eg. `ros2 topic list` will not show available topics, however they are accessible.

#### Option 3: `FASTRTPS_DEFAULT_PROFILES_FILE` env

Create a `ds_client.xml` file with the following content:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<dds>
    <profiles xmlns="http://www.eprosima.com/XMLSchemas/fastRTPS_Profiles">

        <transport_descriptors>
            <transport_descriptor>
                <transport_id>HusarnetTransport</transport_id>
                <type>UDPv6</type>
            </transport_descriptor>
        </transport_descriptors>

        <participant profile_name="client_profile" is_default_profile="true">
            <rtps>
                <userTransports>
                    <transport_id>HusarnetTransport</transport_id>
                </userTransports>
                <useBuiltinTransports>true</useBuiltinTransports>
                <defaultUnicastLocatorList>
                    <locator>
                        <udpv6>
                            <address>husarnet-local</address>
                        </udpv6>
                    </locator>
                </defaultUnicastLocatorList>
                <builtin>
                    <discovery_config>
                        <discoveryProtocol>SUPER_CLIENT</discoveryProtocol>
                        <discoveryServersList>
                            <RemoteServer prefix="44.53.00.5f.45.50.52.4f.53.49.4d.41">
                                <metatrafficUnicastLocatorList>
                                    <locator>
                                        <udpv6>
                                            <address>rosbot2r</address>
                                            <port>11811</port>
                                        </udpv6>
                                    </locator>
                                </metatrafficUnicastLocatorList>
                            </RemoteServer>
                        </discoveryServersList>
                    </discovery_config>
                </builtin>
            </rtps>
        </participant>
    </profiles>
</dds>
```

and set the env:

```
export FASTRTPS_DEFAULT_PROFILES_FILE=$(pwd)/ds_client.xml
ros2 daemon stop
```
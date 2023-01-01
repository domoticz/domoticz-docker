

Domoticz
======

Domoticz - http://www.domoticz.com/

Docker containers with official Domoticz (beta) builds.

*Currently available for the following Linux platforms:*

| Image Architectures |
| :----: |
| Arm 32 bit |
| Arm 64 bit |
| Linux 64 bit |

Repository: https://hub.docker.com/repository/docker/domoticz/domoticz

Domoticz is a Home Automation System that lets you monitor and configure various devices like: Lights, Switches, various sensors/meters like Temperature, Rain, Wind, UV, Electra, Gas, Water and much more. Notifications/Alerts can be sent to any mobile device

## How to use

The recommended method is to use Docker Compose (See below)
For instructions how to install docker (server version) and docker compose see:
https://docs.docker.com/engine/install/
https://docs.docker.com/compose/install/linux/#install-using-the-repository

### Usage with docker-compose

    mkdir /opt/domoticz
    cd /opt/domoticz
Inside this folder create a file (*docker-compose.yml*) with the following contents

*docker-compose.yml*
```yaml
version: '3.3'

services:
  domoticz:
    image: domoticz/domoticz:stable
    container_name: domoticz
    restart: unless-stopped
    # Pass devices to container
    # devices:
    #   - "/dev/serial/by-id/usb-0658_0200-if00-port0:/dev/ttyACM0"
    ports:
      - "8080:8080"
    volumes:
      - ./config:/opt/domoticz/userdata
    environment:
      - TZ=Europe/Amsterdam
      #- LOG_PATH=/opt/domoticz/userdata/domoticz.log
```
If you are using a serial device, uncomment the line above and replace with the correct serial device. (can be found by issuing ls -al /dev/serial/by-id)

Depending on your system, you can now launch the container by issuing:

    docker-compose up -d
or

    docker compose up -d
**(Note the difference with/without the dash, this also applies for instructions below)**

_You can also specify a specific version to use with:_
**image: domoticz/domoticz:beta** _(will pull latest beta version)_  
**image: domoticz/domoticz:stable** _(will pull latest stable version)_  
**image: domoticz/domoticz:2022.2** _(will pull latest stable version 2022.2)_  
**image: domoticz/domoticz:2022-beta.12345** _(will pull beta with build number 12345)_  


### Environment values
**ENV WWW_PORT=8080** - Specify default HTTP port  
**ENV SSL_PORT=443** - Specify default SSL port  
**ENV TZ=Europe/Amsterdam** - Specify default timezone (see /usr/share/zoneinfo folder), **only needed when you can not mount the volume /etc/localtime**  
**EXTRA_CMD_ARG** - Option to override additional command line parameters (See domoticz --help or [wiki page](https://www.domoticz.com/wiki/Command_line_parameters))

You could use the extra_cmd_arg value to specify the SSL certificate

### Usage with traditional docker (non-compose)
**Pull image**

```
docker pull domoticz/domoticz
```

_You can also specify a specific version to use with:_
**docker pull domoticz/domoticz:beta** _(will pull latest beta version)_  
**docker pull domoticz/domoticz:stable** _(will pull latest stable version)_  
**docker pull domoticz/domoticz:2022.2** _(will pull latest stable version 2021.1)_  
**docker pull domoticz/domoticz:2022-beta.12345** _(will pull beta with build number 12345)_  

**Run container**

```
docker run -d \
    -p 8080:8080 \
    -p 8443:443 \
    -v <path for config files>:/opt/domoticz/userdata \
    -e TZ=Europe/Amsterdam
    --device=<device_id> \
    --name=<container name> \ 
    domoticz/domoticz
```

Please replace all user variables in the above command defined by <> with the correct values (you can have several USB devices attached, just add other `--device=<device_id>`).

### Custom startup script for the container
The container supports running a custom (bash) script before the domoticz process starts.
This way, you can customize anything in the container that you need:
- install incremental apt packages (don't forget to apt update before you apt install)
- install incremental python functions (pip3 install)
- and so on/forth
The container calls a script named customstart.sh in userdata, if that script exists.
Please note that the script gets called on EVERY start of the container, not just at creation time.
If you want the script to run only once, you need to build that in your script (e.g. test for a file you create in the script)

### Python Plugins
When launching the docker container for the first time, a plugin folder is created in the *userdata* folder
You need to place your python plugins is folder

### Updating the image
From within the container folder issue:
```
docker-compose pull domoticz
docker-compose down
docker-compose up -d --remove-orphans
docker image prune
```


**Access Domoticz**

```
http://<host ip>:8080
*or*
https://<host ip>:8443
```

8080 can be another port (you change `-p 8080:8080` to `-p 8081:8080` to have 8081 out of the container for example).

### Logging
Logging is disabled by default, and you can see the interna logs via the web gui.
When you enable logging, keep in mind that the log file can become quite large.
Do not leave this enabled when not needed.

### Shell access whilst the container is running
```
docker exec -it domoticz 
```

### Monitor the logs of the container
```
docker logs -f domoticz
```

### Building the image
clone the github repository and issue the build.sh script (you might want to edit this file)



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

**Pull image**

```
docker pull domoticz/domoticz
```

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

**Access Domoticz**

```
http://<host ip>:8080
*or*
https://<host ip>:8443
```

8080 can be another port (you change `-p 8080:8080` to `-p 8081:8080` to have 8081 out of the container for example).

### Usage with docker-compose

    mkdir /opt/domoticz
    cd /opt/domoticz
Inside this folder create a file (*docker-compose.yml*) with the following contents

*docker-compose.yml*
```yaml
version: '3.3'

services:
  domoticz:
    image: domoticz/domoticz
    container_name: domoticz
    restart: unless-stopped
    # Pass devices to container
    # devices:
    #   - "/dev/serial/by-id/usb-0658_0200-if00:/dev/ttyACM0"
    ports:
      - "8080:8080"
    volumes:
      - ./config:/opt/domoticz/userdata
    environment:
      - TZ=Europe/Amsterdam
      #- LOG_PATH=/opt/domoticz/userdata/domoticz.log
```
Now you can launch the container by issuing:

    docker-compose up -d

### Enviroment values
 **ENV WWW_PORT=8080** - Specify default HTTP port  
 **ENV SSL_PORT=443** - Specify default SSL port  
 **ENV TZ=Europe/Amsterdam** - Specify default timezone (see /usr/share/zoneinfo folder), **only needed when you can not mount the volume /etc/localtime**  
 **EXTRA_CMD_ARG** - Option to override additional command line parameters (See domoticz --help or [wiki page](https://www.domoticz.com/wiki/Command_line_parameters))

You could use the extra_cmd_arg value to specify the SSL certificate

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

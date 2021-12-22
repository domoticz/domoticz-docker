# Domoticz

Domoticz - http://www.domoticz.com/

Docker containers with official Domoticz stable and beta builds. Currently available are platforms for:

* Linux ARM v7 32 bit
* Linux ARM 64 bit
* Linux Intel/AMD 64 bit

Repository: https://hub.docker.com/repository/docker/domoticz/domoticz

[Domoticz](http://www.domoticz.com/) is a Home Automation System that lets you monitor and configure various devices like: lights, switches, sensors/meters like temperature, rain, wind, UV, electra, gas, water, and much more. Notifications and alerts can be sent to any mobile device.

## How to use

The recommended method is to use Docker Compose (see below).

### Pull image

Pull the latest image:
```shell
$ docker pull domoticz/domoticz
```

Pull the latest beta version:
```shell
$ docker pull domoticz/domoticz:beta
```

Pull the latest stable version:
```shell
$ docker pull domoticz/domoticz:stable
```

Pull stable version 2021.1:
```shell
$ docker pull domoticz/domoticz:2021.1
```

Pull beta with build number 12345:
```shell
$ docker pull domoticz/domoticz:2021-beta.12345
```

### Run container

```shell
$ docker run -d \
    -p 8080:8080 \
    -p 8443:443 \
    -v <path for config files>:/opt/domoticz/userdata \
    -e TZ=Europe/Amsterdam \
    --device=<device_id> \
    --name=<container name> \
    domoticz/domoticz
```

Please replace all user variables in the above command defined by <> with the correct values (you can have several USB devices attached, just add other `--device=<device_id>`).

### Access Domoticz

Depending on the configured port:

* http://<host ip>:8080
* https://<host ip>:8443

8080 can be another port (you change `-p 8080:8080` to `-p 8081:8080` to have 8081 out of the container for example).

### Usage with docker-compose

```shell
$ mkdir /opt/domoticz
$ cd /opt/domoticz
```
Inside this folder create `docker-compose.yml` with the following contents:

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

```shell
$ docker-compose up -d
```

### Environment variables

| Variable       | Default value    | Description                                                  |
| -------------- | ---------------- | ------------------------------------------------------------ |
| WWW_PORT       | 8080             | Specify default HTTP port                                    |
| SSL_PORT       | 443              | Specify default SSL port (0 for no SSL)                      |
| TZ             | Europe/Amsterdam | Specify default timezone (see /usr/share/zoneinfo folder), only needed when you can not mount the volume /etc/localtime |
| EXTRA_CMD_ARG  |                  | Option to override additional command line parameters (see `domoticz --help` or the [documentation](https://www.domoticz.com/wiki/Command_line_parameters)) |
| EXTRA_PACKAGES |                  | Extra Debian APT packages to be installes, e.g. `python3-requests`, etc. Space delimited. |

### Python Plugins
When launching the docker container for the first time, a plugin folder is created in the `userdata` folder. You need to place your python plugins in this folder.

## Maintenance

### Updating the image
From within the container folder issue:
```shell
$ docker-compose pull domoticz
$ docker-compose down
$ docker-compose up -d --remove-orphans
$ docker image prune
```

### Logging
You can see the internal logs via the web gui. Logging to disk is disabled by default.
When you enable disk logging, keep in mind that the log file can become quite large.
Do not leave this enabled when not needed.

### Shell access whilst the container is running
```shell
$ docker exec -it domoticz
```

### Monitor the logs of the container
```shell
$ docker logs -f domoticz
```

### Building the image
Clone the github repository and issue the `build.sh` script.

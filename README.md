Domoticz
======

Domoticz - http://www.domoticz.com/

Docker containers with official Domoticz (beta) builds

**THIS IS A WORK IN PROGRESS AND IS NOT FINISHED YET, FEEL FREE TO HELP!**

## How to use

**Pull image**

```
docker pull domoticz/domoticz:$VERSION

```

**Run container**

```
docker run -d \
    -p 8080:8080 \
    -p 8443:443 \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    --device=<device_id> \
    --name=<container name> \ 
    domoticz/domoticz:$VERSION
```

Please replace all user variables in the above command defined by <> with the correct values (you can have several USB devices attached, just add other `--device=<device_id>`).

**Access Domoticz**

```
http://<host ip>:8080
```

8080 can be another port (you change `-p 8080:8080` to `-p 8081:8080` to have 8081 out of the container for example).

### Usage with docker-compose

```yaml
version: '3.3'

services:
  domoticz:
    image: domoticz/domoticz
    container_name: domoticz
    restart: unless-stopped
    # Pass devices to container
    # devices:
    #   - "dev/serial/by-id/usb-0658_0200-if00:/dev/ttyACM0"

    volumes:
      - /etc/localtime:/etc/localtime:ro
      #- ./log:/var/log
      #- ./config:/config
      - ./plugins:/opt/domoticz/plugins
    environment:
      #ENV LOG_PATH=/var/log/domoticz.log
      #ENV DATABASE_PATH=/config/domoticz.db
      #ENV WWW_PORT=8080
      #ENV SSL_PORT=443
```

### Building the image

```
docker buildx build --no-cache --platform linux/arm/v6,linux/arm/v7,linux/arm64/v8,linux/amd64 --build-arg APP_HASH="12345" --build-arg BUILD_DATE="2021-01-29T13:51:00z" --tag domoticz/domoticz .
```
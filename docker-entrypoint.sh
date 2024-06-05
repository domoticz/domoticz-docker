#!/bin/bash

CMD_ARGS="-www $WWW_PORT"
CMD_ARGS="$CMD_ARGS -noupdates -sslwww $SSL_PORT -userdata /opt/domoticz/userdata"

if [ -n "$LOG_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -log $LOG_PATH"
fi

if [ -n "$DATABASE_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -dbase $DATABASE_PATH"
fi

if [ -n "$EXTRA_CMD_ARG" ]; then
  CMD_ARGS="$CMD_ARGS $EXTRA_CMD_ARG"
fi

# check if the examples/templates script folder exists, if not create them
if [ ! -d "/opt/domoticz/userdata/scripts/dzVents/data" ]; then
	mkdir -p /opt/domoticz/userdata/scripts/dzVents/data
	cp -R /opt/domoticz/scripts/templates /opt/domoticz/userdata/scripts
	cp -R /opt/domoticz/scripts/dzVents/examples /opt/domoticz/userdata/scripts/dzVents
fi

# copy default customstart into place (-n = no overwrite)
cp -n /opt/domoticz/customstart.sh /opt/domoticz/userdata/customstart.sh

# presence of this file implies the container is already configured
FIRSTRUN="/opt/domoticz/FIRSTRUN"

# perform additional configuration if required
if [ ! -f "$FIRSTRUN" ] ; then

   echo "Running customstart.sh ..."
   source /opt/domoticz/userdata/customstart.sh

   # ensure working directory not changed by customstart script
   cd /opt/domoticz

fi

# mark/update the container as configured
touch "$FIRSTRUN"

if [ $1 == "/opt/domoticz/domoticz" ]; then
  exec $@ $CMD_ARGS
else
  exec "$@"
fi

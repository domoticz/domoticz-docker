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

if [ -f /opt/domoticz/userdata/customstart.sh ]; then
	source /opt/domoticz/userdata/customstart.sh
	cd /opt/domoticz
fi

if [ $1 == "/opt/domoticz/domoticz" ]; then
  exec $@ $CMD_ARGS
else
  exec "$@"
fi

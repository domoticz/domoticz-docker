#!/bin/bash

CMD_ARGS="-www ${WWW_PORT:-8080}"
CMD_ARGS="$CMD_ARGS -noupdates -sslwww ${SSL_PORT:-0} -userdata /opt/domoticz/userdata"

if [ -n "$LOG_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -log $LOG_PATH"
fi

if [ -n "$DATABASE_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -dbase $DATABASE_PATH"
fi

if [ -n "$EXTRA_CMD_ARG" ]; then
  CMD_ARGS="$CMD_ARGS $EXTRA_CMD_ARG"
fi

if [ -n "$EXTRA_PACKAGES" ]; then
  for PACKAGE in $EXTRA_PACKAGES; do
    update=
    if ! dpkg -l $PACKAGE > /dev/null 2>&1; then
    	test -z "$update" && apt-get update
    	apt-get -y install $PACKAGE
    	update=1
    fi
    test -n "$update" && rm -rf /var/lib/apt/lists/*
  done
fi

if [ $1 == "/opt/domoticz/domoticz" ]; then
  exec $@ $CMD_ARGS
else
  exec "$@"
fi

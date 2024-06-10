#!/bin/bash

TEMPLATE="/opt/domoticz"
USERDATA="${TEMPLATE}/userdata"
SCRIPTS="${USERDATA}/scripts"
WEBROOT="${TEMPLATE}/www"

CMD_ARGS="-www $WWW_PORT"
CMD_ARGS="$CMD_ARGS -noupdates -sslwww $SSL_PORT -userdata ${USERDATA}"

if [ -n "$LOG_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -log $LOG_PATH"
fi

if [ -n "$DATABASE_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -dbase $DATABASE_PATH"
fi

if [ -n "$EXTRA_CMD_ARG" ]; then
  CMD_ARGS="$CMD_ARGS $EXTRA_CMD_ARG"
fi

echo "$(date "+%F %T.%3N")  Launch: Begin container self-repair"
rsync -airp --ignore-existing --mkpath "${TEMPLATE}/plugins/examples"         "${USERDATA}/plugins"
rsync -airp --ignore-existing          "${TEMPLATE}/customstart.sh"           "${USERDATA}"
rsync -airp                   --mkpath "${TEMPLATE}/www-templates/"           "${WEBROOT}/templates"
rsync -airp --ignore-existing --mkpath "${TEMPLATE}/scripts/dzVents/examples" "${SCRIPTS}/dzVents"
chown -R 1000:1000 "${USERDATA}"
echo "$(date "+%F %T.%3N")  Launch: End container self-repair"

# presence of this file implies the container is already configured
FIRSTRUN="${TEMPLATE}/FIRSTRUN"

# perform additional configuration if required
if [ ! -f "$FIRSTRUN" ] ; then

   echo "$(date "+%F %T.%3N")  Launch: Running customstart.sh"
   source ${USERDATA}/customstart.sh

   # ensure working directory not changed by customstart script
   cd ${TEMPLATE}

fi

# mark/update the container as configured
touch "$FIRSTRUN"

if [ $1 == "/opt/domoticz/domoticz" ]; then
  exec $@ $CMD_ARGS
else
  exec "$@"
fi

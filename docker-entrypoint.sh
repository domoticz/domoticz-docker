#!/bin/bash
set -e

CMD_ARGS="-www $WWW_PORT"
CMD_ARGS="$CMD_ARGS -sslwww $SSL_PORT"

if [ -n "$LOG_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -log $LOG_PATH"
fi

if [ -n "$DATABASE_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -dbase $DATABASE_PATH"
fi

exec "$@"

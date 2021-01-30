#!/bin/bash
set -e

CMD_ARGS="-noupdates -www $WWW_PORT -sslwww $SSL_PORT"

if [ -n "$LOG_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -log $LOG_PATH"
fi

if [ -n "$DATABASE_PATH" ]; then
  CMD_ARGS="$CMD_ARGS -dbase $DATABASE_PATH"
fi

exec "$@"

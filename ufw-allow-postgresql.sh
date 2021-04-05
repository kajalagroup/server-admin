#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 3 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <db client IP>"
    echo "$THIS_SCRIPT # of arguments was $#"
    exit 1
fi
if [ -f "$ABORT_FILE" ]; then
    echo "$ABORT_FILE exists, skipping $THIS_SCRIPT"
    exit 1
fi

export TARGET_USER="$1"
export TARGET_HOST="$2"
export DB_CLIENT_IP="$3"
export DB_PORT=5432
export TARGET="${TARGET_USER}@${TARGET_HOST}"

$SCRIPT_DIR/ufw-allow-from-ip-to-port.sh $TARGET_USER $TARGET_HOST $DB_CLIENT_IP $DB_PORT

#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"
export LOCAL_SCRIPT="${THIS_SCRIPT}.remote"

if [ "$#" -ne 3 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <domain>"
    echo "$THIS_SCRIPT # of arguments was $#"
    exit 1
fi
if [ -f "$ABORT_FILE" ]; then
    echo "$ABORT_FILE exists, skipping $THIS_SCRIPT"
    exit 1
fi

export TARGET_USER="$1"
export TARGET_HOST="$2"
export DOMAIN="$3"
export TARGET="${TARGET_USER}@${TARGET_HOST}"

if [ "$ADMIN_EMAIL" == "" ]; then
    export ADMIN_EMAIL="admin@${DOMAIN}"
    echo "ADMIN_EMAIL environment variable not set, using $ADMIN_EMAIL"
fi

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: Setting up letsencrypt for domain $DOMAIN at $TARGET_HOST using admin email $ADMIN_EMAIL"
echo "------------------------------------------------------------------------------------"

$SCRIPT_DIR/run-script.sh $TARGET_USER $TARGET_HOST $TARGET_USER $LOCAL_SCRIPT $DOMAIN $ADMIN_EMAIL
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Done!"

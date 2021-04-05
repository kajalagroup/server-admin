#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 3 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <redis password>"
    echo "$THIS_SCRIPT # of arguments was $#"
    exit 1
fi
if [ -f "$ABORT_FILE" ]; then
    echo "$ABORT_FILE exists, skipping $THIS_SCRIPT"
    exit 1
fi

export TARGET_USER="$1"
export TARGET_HOST="$2"
export TARGET="${TARGET_USER}@${TARGET_HOST}"
export REDIS_PASSWORD="$3"

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: Setting up redis at $TARGET_HOST"
echo "------------------------------------------------------------------------------------"
ssh $TARGET "sudo apt -y install redis"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

TMP="`tempfile`"
cat $SCRIPT_DIR/redis.conf.template | $SCRIPT_DIR/tailor REDIS_PASSWORD "$REDIS_PASSWORD" > $TMP

$SCRIPT_DIR/scp-file.sh $TARGET_USER $TARGET_HOST redis "$TMP" "/etc/redis/redis.conf"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

ssh $TARGET 'sudo systemctl restart redis'
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Done!"

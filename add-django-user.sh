#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"
export LOCAL_SCRIPT="${THIS_SCRIPT}.remote"

if [ "$#" -ne 3 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <new django username>"
    echo "$THIS_SCRIPT # of arguments was $#"
    exit 1
fi
if [ -f "$ABORT_FILE" ]; then
    echo "$ABORT_FILE exists, skipping $THIS_SCRIPT"
    exit 1
fi

export TARGET_USER="$1"
export TARGET_HOST="$2"
export DJANGO_USER="$3"
export TARGET="${TARGET_USER}@${TARGET_HOST}"

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: Setting up new Django user $DJANGO_USER at $TARGET_HOST"
echo "------------------------------------------------------------------------------------"

ssh $TARGET "sudo adduser --disabled-password --gecos '' $DJANGO_USER"
if [ "$?" != "0" ]; then
    echo "Error adding user, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Executing $LOCAL_SCRIPT at ${DJANGO_USER}@${TARGET_HOST}"

$SCRIPT_DIR/run-script.sh $TARGET_USER $TARGET_HOST $DJANGO_USER "$SCRIPT_DIR/$LOCAL_SCRIPT" " "
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Done!"

#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 3 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <remote file name>"
    echo "$THIS_SCRIPT # of arguments was $#"
    exit 1
fi
if [ -f "$ABORT_FILE" ]; then
    echo "$ABORT_FILE exists, skipping $THIS_SCRIPT"
    exit 1
fi

export TARGET_USER="$1"
export TARGET_HOST="$2"
export REMOTE_FILE="$3"
export TARGET="${TARGET_USER}@${TARGET_HOST}"

ssh $TARGET "sudo stat $REMOTE_FILE > /dev/null"
if [ "$?" != "0" ]; then
    echo "Remote file $TARGET:$REMOTE_FILE does not exist, exiting with 1"
    exit 1
fi

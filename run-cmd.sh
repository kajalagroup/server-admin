#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 3 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <remote command to run>"
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
export REMOTE_CMD="$3"

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: Executing '$REMOTE_CMD' at $TARGET"
echo "------------------------------------------------------------------------------------"
ssh $TARGET "$REMOTE_CMD"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi
echo "Done!"

#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -lt 4 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <remote script user> <remote cmd>"
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
export SCRIPT_USER="$3"
export REMOTE_CMD="$4"

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: ssh $SCRIPT_USER@$TARGET_HOST '$REMOTE_CMD'"
echo "------------------------------------------------------------------------------------"

if [ "$SCRIPT_USER" == "root" ]; then
    ssh $TARGET "sudo su -c 'cd /root; ${REMOTE_CMD}' - $SCRIPT_USER"
else
    ssh $TARGET "sudo su -c 'cd /home/${SCRIPT_USER}; ${REMOTE_CMD}' - $SCRIPT_USER"
fi
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi
echo "Done!"

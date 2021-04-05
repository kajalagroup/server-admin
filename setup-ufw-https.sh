#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 2 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname>"
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

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: Setting up firewall for web hosting at $TARGET_HOST"
echo "------------------------------------------------------------------------------------"
ssh $TARGET "sudo ufw --force disable && sudo ufw default deny incoming && sudo ufw allow ssh && sudo ufw allow http && sudo ufw allow https && sudo ufw --force enable"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi
echo "Done!"

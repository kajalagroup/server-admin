#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -lt 4 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <remote script user> <local script file> <remote script parameters>"
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
if [ "$SCRIPT_USER" == "root" ]; then
    export SCRIPT_USER_HOME="/root"
else
    export SCRIPT_USER_HOME="/home/$SCRIPT_USER"
fi
export LOCAL_SCRIPT="$4"
export SCRIPT_FILENAME="`basename $LOCAL_SCRIPT`"
export REMOTE_SCRIPT="$SCRIPT_USER_HOME/$SCRIPT_FILENAME"

echo "REMOTE_SCRIPT=$REMOTE_SCRIPT"

if [ "$#" -eq 4 ]; then
    export REMOTE_CMD="$REMOTE_SCRIPT"
fi
if [ "$#" -eq 5 ]; then
    export REMOTE_CMD="$REMOTE_SCRIPT $5"
fi
if [ "$#" -eq 6 ]; then
    export REMOTE_CMD="$REMOTE_SCRIPT $5 $6"
fi
if [ "$#" -eq 7 ]; then
    export REMOTE_CMD="$REMOTE_SCRIPT $5 $6 $7"
fi
if [ "$#" -eq 8 ]; then
    export REMOTE_CMD="$REMOTE_SCRIPT $5 $6 $7 $8"
fi
if [ "$#" -eq 9 ]; then
    export REMOTE_CMD="$REMOTE_SCRIPT $5 $6 $7 $8 $9"
fi

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: ssh $SCRIPT_USER@$TARGET_HOST '$REMOTE_CMD'"
echo "------------------------------------------------------------------------------------"
echo "export TARGET_USER=$TARGET_USER"
echo "export TARGET_HOST=$TARGET_HOST"
echo "export SCRIPT_USER=$SCRIPT_USER"
echo "export LOCAL_SCRIPT=$LOCAL_SCRIPT"
echo "export REMOTE_SCRIPT=$REMOTE_SCRIPT"

$SCRIPT_DIR/scp-file.sh $TARGET_USER $TARGET_HOST $SCRIPT_USER "$LOCAL_SCRIPT" "$REMOTE_SCRIPT"
if [ "$SCRIPT_USER" != "root" ]; then
    ssh $TARGET "sudo su -c 'cd /home/${SCRIPT_USER}; ${REMOTE_CMD}' - $SCRIPT_USER"
else
    ssh $TARGET "sudo su -c 'cd /root; ${REMOTE_CMD}' - root"
fi
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi
echo "Done!"

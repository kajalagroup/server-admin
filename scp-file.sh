#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 5 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <remote file owner> <local file> <remote file>"
    echo "$THIS_SCRIPT # of arguments was $#"
    exit 1
fi
if [ -f "$ABORT_FILE" ]; then
    echo "$ABORT_FILE exists, skipping $THIS_SCRIPT"
    exit 1
fi

export TARGET_USER="$1"
export TARGET_HOST="$2"
export REMOTE_USER="$3"
export LOCAL_FILE="$4"
export REMOTE_FILE="$5"
export FILENAME="`basename $REMOTE_FILE`"
export REMOTE_TMP_FILE="${FILENAME}.tmp"
export TARGET="${TARGET_USER}@${TARGET_HOST}"

# check that $REMOTE_SCRIPT is absolute path
$SCRIPT_DIR/is-abs-path "$REMOTE_FILE"
if [ "$?" != "0" ]; then
    echo "Remote file $REMOTE_FILE must be absolute path, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

scp $LOCAL_FILE "$TARGET:$REMOTE_TMP_FILE"
ssh $TARGET "sudo mv $REMOTE_TMP_FILE $REMOTE_FILE && sudo chown $REMOTE_USER:$REMOTE_USER $REMOTE_FILE"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Done! Copied to $REMOTE_FILE"

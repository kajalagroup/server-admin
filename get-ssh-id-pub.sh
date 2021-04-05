#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"
export REMOTE_SCRIPT="${THIS_SCRIPT}.remote"

if [ "$#" -ne 3 ]; then
    echo "Usage: $THIS_SCRIPT <login user> <hostname> <remote user>"
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
export TARGET="${TARGET_USER}@${TARGET_HOST}"

echo "------------------------------------------------------------------------------------"
echo " $TARGET:/home/${REMOTE_USER}/.ssh/id_rsa.pub:"
echo "------------------------------------------------------------------------------------"

ssh $TARGET "sudo cat /home/${REMOTE_USER}/.ssh/id_rsa.pub" > /tmp/$REMOTE_USER.pub
cat /tmp/$REMOTE_USER.pub
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "------------------------------------------------------------------------------------"

cat /tmp/$REMOTE_USER.pub | tr -d '\n' | xclip -i -selection clipboard
if [  "$?" == "0" ]; then
    echo "Done! (/tmp/$REMOTE_USER.pub content copied to clipboard)"
else
    echo "Done! (/tmp/$REMOTE_USER.pub content NOT copied to clipboard)"
fi

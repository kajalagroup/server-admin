#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 5 ]; then
    echo "Usage: $THIS_SCRIPT <login user> <hostname> <django username> <local settings or OLD> <remote settings>"
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
export LOCAL_SETTINGS="$4"
export REMOTE_SETTINGS="$5"
export TARGET="${TARGET_USER}@${TARGET_HOST}"

if [ "$LOCAL_SETTINGS" != "OLD" -a  ! -f "$LOCAL_SETTINGS"  ]; then
    echo "Django settings.py file \"$LOCAL_SETTINGS\" does not exist"
    exit 1
fi

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: Deploying Django project update to ${DJANGO_USER}@${TARGET_HOST}"
echo " ... from master branch of existing Git repo"
echo " ... and local settings.py from $LOCAL_SETTINGS"
echo " ... deployed to ${DJANGO_USER}@${TARGET_HOST}:$REMOTE_SETTINGS"
echo "------------------------------------------------------------------------------------"
echo "export THIS_SCRIPT=$THIS_SCRIPT"
echo "export TARGET_USER=$1"
echo "export TARGET_HOST=$2"
echo "export DJANGO_USER=$3"
echo "export LOCAL_SETTINGS=$4"
echo "export REMOTE_SETTINGS=$5"
echo "export TARGET=${TARGET_USER}@${TARGET_HOST}"

if [ "$LOCAL_SETTINGS" != "OLD" ]; then
    $SCRIPT_DIR/scp-file.sh "$TARGET_USER" "$TARGET_HOST" "$DJANGO_USER" "$LOCAL_SETTINGS" "$REMOTE_SETTINGS"
fi
$SCRIPT_DIR/run-script.sh "$TARGET_USER" "$TARGET_HOST" "$DJANGO_USER" "$SCRIPT_DIR/django-upgrade"
if [ "$?" != "0" ]; then
    echo "Run remote script error"
    exit 1
fi
ssh $TARGET "sudo systemctl restart ${DJANGO_USER}.service; sudo systemctl restart ${DJANGO_USER}_huey.service;"

echo "Done!"

#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 6 ]; then
    echo "Usage: $THIS_SCRIPT <login user> <hostname> <django username> <django git repo> <settings file or OLD> <remote settings file>"
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
export DJANGO_DIR="/home/$DJANGO_USER/django"
export GIT_REPO="$4"
export LOCAL_SETTINGS="$5"
export REMOTE_SETTINGS="$6"
export TARGET="${TARGET_USER}@${TARGET_HOST}"

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: Deploying Django project to ${DJANGO_USER}@${TARGET_HOST}"
echo " ... from master branch of Git repo $GIT_REPO"
echo " ... and local settings.py from $LOCAL_SETTINGS"
echo " ... deployed to ${DJANGO_USER}@${TARGET_HOST}:$REMOTE_SETTINGS"
echo "------------------------------------------------------------------------------------"
echo "export TARGET_USER=$1"
echo "export TARGET_HOST=$2"
echo "export DJANGO_USER=$3"
echo "export DJANGO_DIR=/home/$DJANGO_USER/django"
echo "export GIT_REPO=$4"
echo "export LOCAL_SETTINGS=$5"
echo "export REMOTE_SETTINGS=$6"
echo "export TARGET=${TARGET_USER}@${TARGET_HOST}"

# check if the repo exists already to choose between git clone and git pull origin master
$SCRIPT_DIR/is-remote-file.sh "$TARGET_USER" "$TARGET_HOST" "$DJANGO_DIR/manage.py"
if [ "$?" == "1" ]; then
    $SCRIPT_DIR/run-script.sh "$TARGET_USER" "$TARGET_HOST" "$DJANGO_USER" "$SCRIPT_DIR/git-clone-repo.sh" "$GIT_REPO" django
fi
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

if [ "$LOCAL_SETTINGS" != "OLD" ]; then
    $SCRIPT_DIR/scp-file.sh "$TARGET_USER" "$TARGET_HOST" "$DJANGO_USER" "$LOCAL_SETTINGS" "$REMOTE_SETTINGS"
    if [ "$?" != "0" ]; then
        echo "Error, exiting after writing $ABORT_FILE file"
        touch "$ABORT_FILE"
        exit 1
    fi
fi

$SCRIPT_DIR/is-remote-file.sh "$TARGET_USER" "$TARGET_HOST" "/home/$DJANGO_USER/venv"
if [ "$?" == "1" ]; then
    $SCRIPT_DIR/run-script.sh "$TARGET_USER" "$TARGET_HOST" "$DJANGO_USER" "$SCRIPT_DIR/make-venv"
fi
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

$SCRIPT_DIR/run-script.sh "$TARGET_USER" "$TARGET_HOST" "$DJANGO_USER" "$SCRIPT_DIR/django-upgrade"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

# (optional) service restart
ssh $TARGET "sudo systemctl restart ${DJANGO_USER}.service; sudo systemctl restart ${DJANGO_USER}_huey.service;"

echo "Done!"

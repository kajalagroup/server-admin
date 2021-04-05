#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 7 ]; then
    echo "Usage: $THIS_SCRIPT <login user> <hostname> <django user> <django git repo> <local settings> <remote settings> <domain>"
    echo "$THIS_SCRIPT # of arguments was $#"
    echo "login user = your login username which has sudo rights"
    echo "hostname = server hostname (can be different from domain but usually same)"
    echo "django user = username which runs uwsgi, e.g. factoring_prod, factoring_test, myproject, sms_server, etc."
    echo "local settings = settings.py file where it is locally on your computer"
    echo "remote settings = settings file on remote computer, usually /home/DJANGOUSER/django/project/settings.py"
    echo "domain = service domain, e.g. myservice.example.com"
    exit 1
fi
if [ -f "$ABORT_FILE" ]; then
    echo "$ABORT_FILE exists, skipping $THIS_SCRIPT"
    exit 1
fi

export TARGET_USER="$1"
export TARGET_HOST="$2"
export DJANGO_USER="$3"
export GIT_REPO="$4"
export LOCAL_SETTINGS="$5"
export REMOTE_SETTINGS="$6"
export DOMAIN="$7"
export TARGET="${TARGET_USER}@${TARGET_HOST}"
echo "export SCRIPT_DIR=\"$SCRIPT_DIR\""
echo "export TARGET_USER=\"$1\""
echo "export TARGET_HOST=\"$2\""
echo "export DJANGO_USER=\"$3\""
echo "export GIT_REPO=\"$4\""
echo "export LOCAL_SETTINGS=\"$5\""
echo "export REMOTE_SETTINGS=\"$6\""
echo "export DOMAIN=\"$7\""
echo "export TARGET=\"${TARGET_USER}@${TARGET_HOST}\""

$SCRIPT_DIR/add-django-user.sh $TARGET_USER $TARGET_HOST $DJANGO_USER
$SCRIPT_DIR/get-ssh-id-pub.sh $TARGET_USER $TARGET_HOST $DJANGO_USER
$SCRIPT_DIR/pause "Now copy-paste above key to Github/Bitbucket Access key list before continuing."
$SCRIPT_DIR/deploy-django-repo-master.sh $TARGET_USER $TARGET_HOST $DJANGO_USER "$GIT_REPO" "$LOCAL_SETTINGS" "$REMOTE_SETTINGS"
$SCRIPT_DIR/enable-django.sh $TARGET_USER $TARGET_HOST $DJANGO_USER "$DOMAIN"

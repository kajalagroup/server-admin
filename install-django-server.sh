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

export TARGET_USER="$1"
export TARGET_HOST="$2"
export TARGET="${TARGET_USER}@${TARGET_HOST}"

echo "===================================================================================="
echo " $THIS_SCRIPT: Setting up a new server at $TARGET"
echo "===================================================================================="

echo "Next: Setting up hostname"
$SCRIPT_DIR/set-hostname.sh $TARGET_USER $TARGET_HOST

echo "Next: Installing basics"
$SCRIPT_DIR/run-script.sh $TARGET_USER $TARGET_HOST $TARGET_USER $SCRIPT_DIR/setup-basics

echo "Next: Setting up firewall for web server"
$SCRIPT_DIR/setup-ufw-https.sh $TARGET_USER $TARGET_HOST

echo "Next: Setting up fail2ban for blocking unauthorized login attempts"
$SCRIPT_DIR/setup-fail2ban.sh $TARGET_USER $TARGET_HOST

echo "Next: Installing Nginx"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST 'sudo apt install -y nginx uwsgi letsencrypt'

echo "Next: Installing Python related software"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST "sudo apt install -y xmlsec1 libxmlsec1-dev libssl-dev libffi-dev"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST "sudo apt install -y uwsgi-plugin-python3 libz-dev libreadline-dev libgdbm-dev libbz2-dev libncursesw5-dev python3-dev"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST "sudo apt -y install libreadline6-dev libssl-dev libgdbm-dev libc6-dev libsqlite3-dev tk-dev liblzma-dev libdb-dev python3-venv libpq-dev libmemcached-dev postgresql-client"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST "sudo snap install pdftk"

echo "Next: Install wkhtmltopdf 0.12.5.1 (apt install wkhtmltopdf installs 0.12.4 on Ubuntu 18.04)"
ssh $TARGET 'sudo apt remove wkhtmltopdf'
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST 'cd /tmp; wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb'
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST 'sudo gdebi --non-interactive /tmp/wkhtmltox_0.12.5-1.bionic_amd64.deb'

echo "Finishing $THIS_SCRIPT, checking for errors"
if [ -f "$ABORT_FILE" ]; then
    echo "$ABORT_FILE exists, install did not complete without errors. Delete $ABORT_FILE after fixing the issue"
    exit 1
fi
echo "$THIS_SCRIPT DONE!"

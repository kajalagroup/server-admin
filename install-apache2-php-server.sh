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

echo "Next: Setting up fail2ban for blocking unauthorized login attempts"
$SCRIPT_DIR/setup-fail2ban.sh $TARGET_USER $TARGET_HOST

echo "Next: Setting up firewall for web server"
$SCRIPT_DIR/setup-ufw-https.sh $TARGET_USER $TARGET_HOST

echo "Next: Installing Apache2 and certbot"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST 'sudo apt install -y apache2 certbot'

echo "Next: Install PHP versions"
sudo add-apt-repository ppa:ondrej/php && sudo apt update
for ver in 5.6 7.4 8.0; do
    sudo apt install -y php$ver php$ver-fpm 
    sudo apt install -y php$ver-cli php$ver-curl php$ver-mysql php$ver-xml php$ver-mbstring php$ver-soap php$ver-xml php$ver-bcmath php$ver-zip php$ver-gd php$ver-imap php$ver-intl
done

echo "Finishing $THIS_SCRIPT, checking for errors"
if [ -f "$ABORT_FILE" ]; then
    echo "$ABORT_FILE exists, install did not complete without errors. Delete $ABORT_FILE after fixing the issue"
    exit 1
fi
echo "$THIS_SCRIPT DONE!"

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
echo " $THIS_SCRIPT: Setting up fail2ban at $TARGET_HOST"
echo "------------------------------------------------------------------------------------"
ssh $TARGET "sudo apt -y install fail2ban"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

# jail2ban config from https://www.lifewire.com/harden-ubuntu-server-security-4178243
cat >/tmp/jail.local <<__EOF__
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
__EOF__
echo "Wrote following jail.local config:"
cat /tmp/jail.local
echo "(end)"
scp /tmp/jail.local $TARGET:jail.local
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

ssh $TARGET 'sudo cp jail.local /etc/fail2ban/; sudo systemctl restart fail2ban'
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Done!"

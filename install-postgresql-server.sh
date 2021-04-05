#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"
export SCRIPT_DIR_BASENAME="`basename $SCRIPT_DIR`"

if [ "$#" -ne 2 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname>"
    echo "$THIS_SCRIPT # of arguments was $#"
    exit 1
fi

export TARGET_USER="$1"
export TARGET_HOST="$2"
export TARGET="${TARGET_USER}@${TARGET_HOST}"

echo "===================================================================================="
echo " $THIS_SCRIPT: Setting up a PostgreSQL server at $TARGET"
echo "===================================================================================="

echo "Installing basics"
$SCRIPT_DIR/run-script.sh $TARGET_USER $TARGET_HOST $TARGET_USER $SCRIPT_DIR/setup-basics

echo "Setting up basic firewall"
$SCRIPT_DIR/setup-ufw-basic.sh $TARGET_USER $TARGET_HOST

echo "Next: Setting up fail2ban for blocking unauthorized login attempts"
$SCRIPT_DIR/setup-fail2ban.sh $TARGET_USER $TARGET_HOST

echo "Installing PostgreSQL server"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST "sudo apt install -y postgresql"

echo "Installing PostGIS - Spatial and Geographic Objects for PostgreSQL"
export POSTGIS_PACKAGE_NAME="postgresql-12-postgis-3"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST "sudo apt -y install $POSTGIS_PACKAGE_NAME postgresql-contrib postgresql-client-common postgis binutils libproj-dev gdal-bin"

echo "Starting PostgreSQL server"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST "sudo systemctl start postgresql"

echo "Adding $TARGET_USER as PostgreSQL superuser to $TARGET_HOST"
$SCRIPT_DIR/run-script.sh "$TARGET_USER" "$TARGET_HOST" "$TARGET_USER" $SCRIPT_DIR/pg-add-superuser "$TARGET_USER"

echo "NOTE: Firewall blocks connections. Use ./ufw-allow-postgresql.sh to enable client connections."
echo "$THIS_SCRIPT DONE!"

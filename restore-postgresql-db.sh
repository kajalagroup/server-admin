#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 6 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <local .sql.gz file> <remote db name> <remote db password> <db client IP connecting to remote DB>"
    echo "$THIS_SCRIPT # of arguments was $#"
    exit 1
fi

export TARGET_USER="$1"
export TARGET_HOME="/home/$TARGET_USER"
if [ "$TARGET_USER" == "root" ]; then
    export TARGET_HOME="/root"
fi
export TARGET_HOST="$2"
export LOCAL_SQLGZ_FILE="$3"
export SQLGZ_FILENAME="`basename $LOCAL_SQLGZ_FILE`"
export REMOTE_SQLGZ_FILE="$TARGET_HOME/$SQLGZ_FILENAME"
export DB_NAME="$4"
export DB_USER="$4"
export DB_PASS="$5"
export DB_CLIENT_IP="$6"
export TARGET="${TARGET_USER}@${TARGET_HOST}"

echo "===================================================================================="
echo " $THIS_SCRIPT: Setting up a PostgreSQL DB $DB_NAME at $TARGET for DB user $DB_NAME"
echo "===================================================================================="

echo "Opening PostgreSQL server firewall for client connection"
$SCRIPT_DIR/ufw-allow-postgresql.sh $TARGET_USER $TARGET_HOST $DB_DB_CLIENT_IP

echo "Copying source DB .sql.gz to DB server"
$SCRIPT_DIR/scp-file.sh $TARGET_USER $TARGET_HOST $TARGET_USER $LOCAL_SQLGZ_FILE $REMOTE_SQLGZ_FILE

echo "Syncing PostgreSQL helper scripts to DB server"
rsync -aP pg-* $TARGET:.

echo "Restoring $REMOTE_SQL_FILE to database $DB_NAME"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST "./pg-restore $REMOTE_SQLGZ_FILE $DB_NAME"

echo "Settings DB user $DB_NAME password as $DB_PASS"
$SCRIPT_DIR/run-cmd.sh $TARGET_USER $TARGET_HOST "./pg-set-user-password $DB_NAME $DB_PASS"

echo "Appending \"host $DB_USER $DB_USER $DB_CLIENT_IP/32 md5\" to pg_hba.conf file"
export PG_HBA_APPEND_TMP_SCRIPT="/tmp/pg_hba-append-$DB_USER-$DB_CLIENT_IP.sh"
echo "#!/bin/bash" > $PG_HBA_APPEND_TMP_SCRIPT
echo "./pg-append-hba 'host $DB_USER $DB_USER $DB_CLIENT_IP/32 md5'" >> $PG_HBA_APPEND_TMP_SCRIPT
chmod ugo=rwx $PG_HBA_APPEND_TMP_SCRIPT
$SCRIPT_DIR/run-script.sh $TARGET_USER $TARGET_HOST $TARGET_USER $PG_HBA_APPEND_TMP_SCRIPT

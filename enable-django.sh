#!/bin/bash

export ABORT_FILE="/tmp/abort"
export THIS_SCRIPT=$(basename "$0")
export THIS_SCRIPT_FULL_PATH="`realpath $0`"
export SCRIPT_DIR="`dirname $THIS_SCRIPT_FULL_PATH`"

if [ "$#" -ne 4 ]; then
    echo "Usage: $THIS_SCRIPT <user> <hostname> <django username> <django domain>"
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
export DOMAIN="$4"
export TARGET="${TARGET_USER}@${TARGET_HOST}"
export NGINX_CONF_PATH="/etc/nginx/sites-available/${DOMAIN}.conf"
export UWSGI_CONF_PATH="/home/$DJANGO_USER/uwsgi.ini"
export SYSTEMD_CONF_PATH="/etc/systemd/system/${DJANGO_USER}.service"
export NGINX_TMP_PATH="/tmp/${DJANGO_USER}-${DOMAIN}.nginx"
export UWSGI_TMP_PATH="/tmp/${DJANGO_USER}-${DOMAIN}.uwsgi"
export SYSTEMD_TMP_PATH="/tmp/${DJANGO_USER}-${DOMAIN}.systemd"

echo "------------------------------------------------------------------------------------"
echo " $THIS_SCRIPT: Enabling Django $DOMAIN service for $DJANGO_USER at $TARGET_HOST"
echo "------------------------------------------------------------------------------------"

# check valid input
if [ "$DOMAIN" == "" ]; then
    echo "ERROR: Domain cannot be empty, exiting with error 1 after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

# check that Django installed at remote
export DJANGO_REMOTE_FILE="/home/$DJANGO_USER/django/manage.py"
$SCRIPT_DIR/is-remote-file.sh $TARGET_USER $TARGET_HOST "$DJANGO_REMOTE_FILE"
if [ "$?" != "0" ]; then
    echo "Django project not installed on remote server, exiting with error 1 after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

cat $SCRIPT_DIR/django-nginx.conf.template | $SCRIPT_DIR/tailor __DOMAIN__ $DOMAIN | $SCRIPT_DIR/tailor __DJANGO_USER__ $DJANGO_USER > "$NGINX_TMP_PATH"
cat $SCRIPT_DIR/django-uwsgi.ini.template | $SCRIPT_DIR/tailor __DJANGO_USER__ $DJANGO_USER > "$UWSGI_TMP_PATH"
cat $SCRIPT_DIR/django-systemd.service.template | $SCRIPT_DIR/tailor __DJANGO_USER__ $DJANGO_USER > "$SYSTEMD_TMP_PATH"

$SCRIPT_DIR/scp-file.sh $TARGET_USER $TARGET_HOST root "$NGINX_TMP_PATH" "$NGINX_CONF_PATH"
$SCRIPT_DIR/scp-file.sh $TARGET_USER $TARGET_HOST $DJANGO_USER "$UWSGI_TMP_PATH" "$UWSGI_CONF_PATH"
$SCRIPT_DIR/scp-file.sh $TARGET_USER $TARGET_HOST root "$SYSTEMD_TMP_PATH" "$SYSTEMD_CONF_PATH"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Enabling and starting ${DJANGO_USER}.service"
ssh $TARGET "sudo chmod og=rx /home/${DJANGO_USER} && sudo systemctl daemon-reload && sudo systemctl start ${DJANGO_USER}.service && sudo systemctl enable ${DJANGO_USER}.service"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Checking that the ${DJANGO_USER} service is enabled and active"
ssh $TARGET "sudo systemctl is-enabled ${DJANGO_USER}.service && sudo systemctl is-active ${DJANGO_USER}.service"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Getting SSL cert for $DOMAIN"
ssh $TARGET "sudo systemctl stop nginx && sudo certbot certonly -d $DOMAIN"
RV="$?"
ssh $TARGET "sudo systemctl start nginx"
if [ "$RV" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Enabling $DOMAIN and restarting nginx"
ssh $TARGET "sudo ln -s /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/$DOMAIN.conf"
ssh $TARGET "sudo nginx -t"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi
ssh $TARGET "sudo systemctl restart nginx.service"
if [ "$?" != "0" ]; then
    echo "Error, exiting after writing $ABORT_FILE file"
    touch "$ABORT_FILE"
    exit 1
fi

echo "Done!"

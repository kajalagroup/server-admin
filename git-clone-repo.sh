#!/bin/bash

# scan bitbucket.org and github.com keys to ~/.ssh/known_hosts (if needed)
for domain in bitbucket.org github.com; do
    if [ ! -f "$HOME/.ssh/keyscan-$domain" ]; then
        ssh-keyscan $domain >> $HOME/.ssh/known_hosts
        touch $HOME/.ssh/keyscan-$domain
    fi
done

export THIS_SCRIPT=$(basename "$0")

if [ "$#" -ne 2 ]; then
    echo "Usage: $THIS_SCRIPT <repo> <target dir>"
    echo "$THIS_SCRIPT # of arguments was $#"
    exit 1
fi

export GIT_REPO="$1"
export TARGET_DIR="$2"

git clone $GIT_REPO $TARGET_DIR
exit $?

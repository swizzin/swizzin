#!/usr/bin/env bash

#Migration utility

if [[ $EUID -ne 0 ]]; then
    echo "You gotta run this as root yo"
    exit 1
fi

#shellcheck source=sources/globals.sh
. /etc/swizzin/sources/globals.sh
echo_log_only ">>>> \`box $*\`"
echo_log_only "git @ $(git --git-dir=/etc/swizzin/.git rev-parse --short HEAD) 2>&1"

target="$1"
ssh -t "$target" || {
    echo_error "Could not connect to target. Please set up in your config"
}

ssh "$target" -c

users=$(ssh "$target" -C "
    . /etc/swizzin/sources/globals.sh
    _get_user_list | grep -v $(_get_master_username)
")

echo "$users"

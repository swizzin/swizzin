#!/usr/bin/env bash
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ ! -f /install/.authelia.lock ]]; then
    echo_warn "Authelia is not installed"
    exit 1
else
    echo_progress_start "Removing Authelia from the system"
    systemctl disable -q --now authelia &>> "${log}"
    rm_if_exists /etc/authelia
    rm_if_exists /opt/authelia
    echo_progress_done "Done"
fi
#
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Removing Authelia from nginx"
    rm_if_exists /etc/nginx/apps/authelia.conf
    rm_if_exists /etc/nginx/apps/authelia
    systemctl reload -q nginx &>> "${log}"
    echo_progress_done "Done"
fi

rm -f /install/.authelia.lock

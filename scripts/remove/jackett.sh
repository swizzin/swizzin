#!/usr/bin/env bash
#
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
username="$(_get_master_username)"

systemctl disable -q --now jackett &>> "$log"

rm_if_exists "/home/${username}/Jackett"
rm_if_exists "/install/.jackett.lock"
rm_if_exists "/home/${username}/.config/Jackett"
rm_if_exists /etc/systemd/system/jackett
rm_if_exists /etc/nginx/apps/jackett.conf

systemctl reload -q nginx &>> "$log"

if [[ -f /etc/init.d/jackett ]]; then
    rm_if_exists /etc/init.d/jackett
    update-rc.d -f jackett remove
    systemctl stop -q jackett &>> "$log"
fi

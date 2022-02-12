#!/bin/bash
# Flood uninstaller
# Author: liara

readarray -t users < <(_get_user_list)

for user in ${users[@]}; do
    systemctl disable flood@${user} --now -q
    rm -rf /home/${user}/.config/flood
    # Remove deprecated install method, incase the current install is outdated
    rm -rf /home/${user}/.flood
done

if [[ -f /install/.flood.lock ]]; then
    rm -f /etc/nginx/apps/flood.conf
    rm -f /etc/nginx/conf.d/*.flood.conf
    systemctl reload nginx
fi

npm -g remove flood >> "$log" 2>&1

rm -f /etc/systemd/system/flood@.service
rm -f /install/.flood.lock

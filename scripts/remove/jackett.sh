#!/bin/bash
username=$(_get_master_username)

rm -r /home/"$username"/Jackett
rm /install/.jackett.lock
rm -r /home/"${username}"/.config/Jackett

systemctl stop -q jackett@"${username}"
systemctl disable -q jackett@"${username}"
rm /etc/systemd/system/jackett@.service
rm -f /etc/nginx/apps/jackett.conf
systemctl reload nginx
if [[ -f /etc/init.d/jackett ]]; then
    rm /etc/init.d/jackett
    update-rc.d -f jackett remove
    systemctl stop -q jackett
fi

#!/bin/bash
username=$(cut -d: -f1 < /root/.master.info)

rm -r /home/$username/Jackett
rm /install/.jackett.lock
  systemctl stop jackett@${username}
  systemctl disable jackett@${username}
  rm /etc/systemd/system/jackett@.service
  rm -f /etc/nginx/apps/jackett.conf
  service nginx reload
if [[ -f /etc/init.d/jackett ]]; then
  rm /etc/init.d/jackett
  update-rc.d -f jackett remove
  service jackett stop
fi

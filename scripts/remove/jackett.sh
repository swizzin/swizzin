#!/bin/bash
username=$(cat /srv/rutorrent/home/db/master.txt)

rm -r /home/$username/Jackett
rm /install/.jackett.lock
  systemctl stop jackett@${username}
  systemctl disable jackett@${username}
  rm /etc/systemd/system/jackett@.service
  rm -f /etc/apache2/sites-enabled/jackett.conf
  service apache2 reload
if [[ -f /etc/init.d/jackett ]]; then
  rm /etc/init.d/jackett
  update-rc.d -f jackett remove
  service jackett stop
fi

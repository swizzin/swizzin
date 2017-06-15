#!/bin/bash
username=$(cat /srv/rutorrent/home/db/master.txt)

apt -y remove par2-tbb python-openssl python-sabyenc python-cheetah >/dev/null 2>&1
rm -rf /home/$username/SABnzbd
systemctl disable sabnzbd@$username
systemctl stop sabnzbd@$username
rm /etc/systemd/system/sabnzbd@.service
rm -f /etc/apache2/sites-enabled/sabnzbd.conf
rm /install/.sabnzbd.lock

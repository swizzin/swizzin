#!/bin/bash
username=$(cut -d: -f1 < /root/.master.info)

apt-get -y remove par2-tbb python-openssl python-sabyenc python-cheetah >/dev/null 2>&1
rm -rf /home/$username/SABnzbd
systemctl disable sabnzbd@$username
systemctl stop sabnzbd@$username
rm /etc/systemd/system/sabnzbd@.service
rm -f /etc/nginx/apps/sabnzbd.conf
service nginx force-reload
rm /install/.sabnzbd.lock

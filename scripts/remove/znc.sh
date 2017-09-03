#!/bin/bash
#ZNC Removal

systemctl disable znc >> /dev/null 2>&1
systemctl stop znc >> /dev/null 2>&1
sudo -u znc crontab -l | sed '/znc/d' | crontab -u znc -
apt-get remove -y -q znc  >> /dev/null 2>&1
userdel -rf znc >> /dev/null 2>&1
groupdel -f znc >> /dev/null 2>&1
rm /install/.znc.lock

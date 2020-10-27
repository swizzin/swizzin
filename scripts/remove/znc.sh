#!/bin/bash
#ZNC Removal

systemctl disable -q znc
systemctl stop -q znc 
sudo -u znc crontab -l | sed '/znc/d' | crontab -u znc -
apt_remove znc
userdel -rf znc 
groupdel -f znc 
rm /install/.znc.lock

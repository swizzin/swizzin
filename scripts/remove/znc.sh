#!/bin/bash

sudo -u znc crontab -l | sed '/znc/d' | crontab -u znc -
apt-get remove -y -q znc
userdel -rf znc
groupdel -rf znc
rm /install/.znc.lock

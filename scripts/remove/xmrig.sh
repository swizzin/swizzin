#!/bin/bash

user=$(_get_master_username)
systemctl disable --now -q xmrig
su - "${user}" -c "screen -X -S xmrig quit" > /dev/null 2>&1
rm -rf /home/"${user}"/.xmrig
rm -rf /etc/systemd/system/xmrig.service
rm -rf /usr/local/bin/xmrig
rm -rf /install/.xmrig.lock

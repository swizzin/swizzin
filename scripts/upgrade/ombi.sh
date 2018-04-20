#!/bin/bash
# Upgrade ombi
# Author liara
echo "Upgrading Ombi. Please wait ... "

user=$(cat /root/.master.info | cut -d: -f1)
systemctl stop ombi
cd /opt
cp ombi/Ombi.sqlite .
rm -rf ombi
wget -q -O Ombi.zip https://github.com/tidusjar/Ombi/releases/download/v2.2.1/Ombi.zip
unzip Ombi.zip >/dev/null 2>&1
mv Release ombi
mv Ombi.sqlite ombi
rm Ombi.zip
chown -R ${user}: ombi
systemctl start ombi
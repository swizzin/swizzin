#!/bin/bash
# Upgrade ombi
# Author liara
echo "Upgrading Ombi. Please wait ... "

user=$(cat /root/.master.info | cut -d: -f1)
systemctl stop ombi
cd /opt
cp ombi/Ombi.sqlite .
rm -rf ombi
curl -sL https://git.io/vKEJz | grep release | grep zip | cut -d "\"" -f 2 | sed -e 's/\/tidusjar/https:\/\/github.com\/tidusjar/g' | xargs wget --quiet -O Ombi.zip >/dev/null 2>&1
unzip Ombi.zip >/dev/null 2>&1
mv Release ombi
mv Ombi.sqlite ombi
rm -rf Ombi.zip
chown -R ${user}: ombi
systemctl start ombi
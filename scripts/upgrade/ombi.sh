#!/bin/bash
# Upgrade ombi
# Author liara
echo "Upgrading Ombi. Please wait ... "

user=$(cat /root/.master.info | cut -d: -f1)
systemctl stop ombi
cd /opt
curl -sL https://git.io/vKEJz | grep release | grep zip | cut -d "\"" -f 2 | sed -e 's/\/tidusjar/https:\/\/github.com\/tidusjar/g' | xargs wget --quiet -O Ombi.zip >/dev/null 2>&1
mkdir ombi
mv Ombi.zip ombi
cd ombi
unzip Ombi.zip >/dev/null 2>&1
rm Ombi.zip
cd /opt
chown -R ${user}: ombi
systemctl start ombi
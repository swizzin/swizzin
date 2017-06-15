#!/bin/bash
#
# [Quick Box :: Install Subsonic package]
#
# QUICKLAB REPOS
# QuickLab _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

OUTTO=/srv/rutorrent/home/db/output.log
local_setup=/etc/QuickBox/setup/
MASTER=$(cat /srv/rutorrent/home/db/master.txt)


echo "Creating subsonic-tmp install directory ... " >>"${OUTTO}" 2>&1;
mkdir /root/subsonic-tmp

echo "Downloading Subsonic dependencies and installing ... " >>"${OUTTO}" 2>&1;
apt -yf install openjdk-8-jre
wget -O /root/subsonic-tmp/subsonic.deb https://s3-eu-west-1.amazonaws.com/subsonic-public/download/subsonic-6.0.deb
cd /root/subsonic-tmp
dpkg -i subsonic.deb

touch /install/.subsonic.lock

echo "Removing subsonic-tmp install directory ... " >>"${OUTTO}" 2>&1;
cd
rm -rf /root/subsonic-tmp

echo "Modifying Subsonic startup script ... " >>"${OUTTO}" 2>&1;
cp -f ${local_setup}templates/subsonic/subsonic.sh.template /usr/share/subsonic/subsonic.sh

echo "Enabling Subsonic Systemd configuration" >>"${OUTTO}" 2>&1;
service stop subsonic >/dev/null 2>&1
cp ${local_setup}templates/sysd/subsonic.template /etc/systemd/system/subsonic.service
sed -i "s/MASTER/${MASTER}/g" /etc/systemd/system/subsonic.service
mkdir /srv/subsonic
chown ${MASTER}: /srv/subsonic
systemctl enable subsonic.service >/dev/null 2>&1
systemctl start subsonic.service >/dev/null 2>&1

cat > /etc/apache2/sites-enabled/subsonic.conf <<EOF
<Location /subsonic>
ProxyPass http://localhost:4040/subsonic
ProxyPassReverse http://localhost:4040/subsonic
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${MASTER}
</Location>
EOF
chown www-data: /etc/apache2/sites-enabled/subsonic.conf
service apache2 reload
service subsonic restart

echo "Subsonic Install Complete!" >>"${OUTTO}" 2>&1;
sleep 2
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;

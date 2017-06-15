#!/bin/bash
#
# [Quick Box :: Install syncthing]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | lizaSB
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

local_setup=/etc/QuickBox/setup/
OUTTO=/srv/rutorrent/home/db/output.log
MASTER=$(cat /srv/rutorrent/home/db/master.txt)

echo "Adding Syncthing Repository ... " >>"${OUTTO}" 2>&1;
curl -s https://syncthing.net/release-key.txt | sudo apt-key add - > /dev/null 2>&1
echo "deb http://apt.syncthing.net/ syncthing release" > /etc/apt/sources.list.d/syncthing.list

echo "Installing Syncthing ... " >>"${OUTTO}" 2>&1;
sudo apt-get -q update > /dev/null 2>&1
sudo apt-get -qy install syncthing > /dev/null 2>&1

echo "Configuring Syncthing & Starting ... " >>"${OUTTO}" 2>&1;
cp ${local_setup}templates/sysd/syncthing.template /etc/systemd/system/syncthing@.service
systemctl enable syncthing@${MASTER} > /dev/null 2>&1
systemctl start syncthing@${MASTER} > /dev/null 2>&1

cat > /etc/apache2/sites-enabled/syncthing.conf <<EOF
<Location /syncthing>
ProxyPass http://localhost:8384
ProxyPassReverse http://localhost:8384
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${MASTER}
</Location>
EOF
chown www-data: /etc/apache2/sites-enabled/syncthing.conf
service apache2 reload

touch /install/.syncthing.lock
echo "Syncthing installation complete!" >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;

#!/bin/bash
#
# [Quick Box :: Install plexpy ]
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
#
OUTTO=/srv/rutorrent/home/db/output.log
local_setup=/etc/QuickBox/setup/
MASTER=$(cat /root/.master.info | cut -d: -f1)


cd /opt
echo "Cloning PlexPy repository" >>"${OUTTO}" 2>&1;
git clone https://github.com/drzoidberg33/plexpy.git > /dev/null 2>&1

echo "Adding user and setting up PlexPy" >>"${OUTTO}" 2>&1;
adduser --system --no-create-home plexpy

echo "Adjusting permissions" >>"${OUTTO}" 2>&1;
chown plexpy:nogroup -R /opt/plexpy


cat > /etc/apache2/sites-enabled/plexpy.conf <<EOF
<Location /plexpy>
ProxyPass http://localhost:8181/plexpy
ProxyPassReverse http://localhost:8181/plexpy
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${MASTER}
</Location>
EOF
chown www-data: /etc/apache2/sites-enabled/plexpy.conf
service apache2 reload

echo "Enabling PlexPy Systemd configuration"
cp ${local_setup}templates/sysd/plexpy.template /etc/systemd/system/plexpy.service
systemctl enable plexpy > /dev/null 2>&1
systemctl start plexpy
systemctl stop plexpy
systemctl start plexpy
systemctl stop plexpy
sed -i "s/http_root.*/http_root = \"plexpy\"/g" /opt/plexpy/config.ini
sed -i "s/http_host.*/http_host = localhost/g" /opt/plexpy/config.ini
systemctl start plexpy
touch /install/.plexpy.lock

echo "PlexPy Install Complete!" >>"${OUTTO}" 2>&1;
sleep 5
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;

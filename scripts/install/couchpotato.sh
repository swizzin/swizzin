#!/bin/bash
#
# [Quick Box :: Install systemd services]
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
function _install() {
echo "Installing CouchPotato ... " >>"${OUTTO}" 2>&1;
warning=$(echo -e "[ \e[1;91mWARNING\e[0m ]")
apt-get -y --force-yes update >/dev/null 2>&1
apt-get -y --force-yes install git-core python >/dev/null 2>&1;
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Cloning CouchPotato git ... " >>"${OUTTO}" 2>&1;
git clone -q https://github.com/CouchPotato/CouchPotatoServer.git /home/${MASTER}/.couchpotato || (echo "GIT failed" && exit 1)
chown ${MASTER}:${MASTER} -R /home/${MASTER}/.couchpotato
}

function _services(){
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Installing and enabling service ... " >>"${OUTTO}" 2>&1;

cp ${local_setup}templates/sysd/couchpotato.template /etc/systemd/system/couchpotato@.service
systemctl enable couchpotato@${MASTER} >/dev/null 2>&1
systemctl start couchpotato@${MASTER} >/dev/null 2>&1
systemctl stop couchpotato@${MASTER} >/dev/null 2>&1

sed -i "s/url_base.*/url_base = couchpotato\nhost = localhost/g" /home/${MASTER}/.couchpotato/settings.conf

cat > /etc/apache2/sites-enabled/couchpotato.conf <<EOF
<Location /couchpotato>
ProxyPass http://localhost:5050/couchpotato
ProxyPassReverse http://localhost:5050/couchpotato
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${MASTER}
</Location>
EOF
chown www-data: /etc/apache2/sites-enabled/couchpotato.conf
service apache2 reload
systemctl start couchpotato@${MASTER} >/dev/null 2>&1

touch /install/.couchpotato.lock
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
}

local_setup=/etc/QuickBox/setup/
OUTTO=/srv/rutorrent/home/db/output.log
MASTER=$(cat /root/.master.info | cut -d: -f1)
_install
_services

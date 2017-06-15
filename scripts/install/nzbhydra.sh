#!/bin/bash
#
# [Quick Box :: Install nzbhydra package]
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
# for output to dashboard
echo "Installing NZBHydra ... " >>"${OUTTO}" 2>&1;
# for output to box
#echo "Installing NZBHydra ... "
warning=$(echo -e "[ \e[1;91mWARNING\e[0m ]")
apt -y update >/dev/null 2>&1
apt -y install git-core python >/dev/null 2>&1;
##echo >>"${OUTTO}" 2>&1;
echo "Cloning NZBHydra git ... " >>"${OUTTO}" 2>&1;
git clone -q https://github.com/theotherp/nzbhydra.git /home/${MASTER}/nzbhydra || (echo "GIT failed" && exit 1)
chown ${MASTER}:${MASTER} -R /home/${MASTER}/nzbhydra
mkdir /home/${MASTER}/.nzbhydra
chown ${MASTER}:${MASTER} -R /home/${MASTER}/.nzbhydra
}

function _services(){
# for output to dashboard
echo "Installing and enabling service ... " >>"${OUTTO}" 2>&1;
# for output to box
echo "Installing and enabling service ... "

cp ${local_setup}templates/sysd/nzbhydra.template /etc/systemd/system/nzbhydra@.service
sed -i "s/USER/${MASTER}/g" /etc/systemd/system/nzbhydra@.service
mkdir -p /home/${MASTER}/.nzbhydra
chown ${MASTER}:${MASTER} -R /home/${MASTER}/.nzbhydra
systemctl enable nzbhydra@${MASTER} >/dev/null 2>&1
systemctl start nzbhydra@${MASTER} >/dev/null 2>&1
sleep 30
systemctl stop nzbhydra@${MASTER} >/dev/null 2>&1

sed -i "s/urlBase.*/urlBase\": \"\/nzbhydra\",/g"  /home/"${MASTER}"/.nzbhydra/settings.cfg
sed -i "s/host.*/host\": \"127.0.0.1\",/g"  /home/"${MASTER}"/.nzbhydra/settings.cfg

cat > /etc/apache2/sites-enabled/nzbhydra.conf <<EOF
<Location /nzbhydra>
ProxyPass http://localhost:5075/nzbhydra/
ProxyPassReverse http://localhost:5075/nzbhydra/
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${MASTER}
</Location>
EOF
chown www-data: /etc/apache2/sites-enabled/nzbhydra.conf
service apache2 reload
systemctl start nzbhydra@${MASTER} >/dev/null 2>&1

touch /install/.nzbhydra.lock
# for output to dashboard
echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
# for output to box
echo
echo
# for output to dashboard
echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;
}

local_setup=/etc/QuickBox/setup/
OUTTO=/srv/rutorrent/home/db/output.log
MASTER=$(cat /srv/rutorrent/home/db/master.txt)
_install
_services

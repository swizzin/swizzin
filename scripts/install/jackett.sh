#!/bin/bash
#
# [Quick Box :: Install Jackett package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | d2dyno
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

OUTTO=/srv/rutorrent/home/db/output.log
username=$(cat /srv/rutorrent/home/db/master.txt)
local_setup=/etc/QuickBox/setup/
jackettver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | grep -v repository | awk -F "[><]" '{print $3}')
echo >>"${OUTTO}" 2>&1;
echo "Installing Jackett ... " >>"${OUTTO}" 2>&1;

if [[ ! -f /etc/apt/sources.list.d/mono-xamarin.list ]]; then
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF >/dev/null 2>&1
  echo "deb http://download.mono-project.com/repo/debian wheezy main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
  echo "deb http://download.mono-project.com/repo/debian wheezy-libjpeg62-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
  echo "deb http://download.mono-project.com/repo/debian wheezy-apache24-compat main" | tee -a /etc/apt/sources.list.d/mono-xamarin.list >/dev/null 2>&1
fi

apt update -y >/dev/null 2>&1
apt install -y mono-devel >/dev/null 2>&1

cd /home/$username
wget -q https://github.com/Jackett/Jackett/releases/download/$jackettver/Jackett.Binaries.Mono.tar.gz
tar -xvzf Jackett.Binaries.Mono.tar.gz > /dev/null 2>&1
rm -f Jackett.Binaries.Mono.tar.gz
chown ${username}.${username} -R Jackett
touch /install/.jackett.lock

cp ${local_setup}templates/sysd/jackett.template /etc/systemd/system/jackett@.service
systemctl enable jackett@${username} >/dev/null 2>&1
systemctl start jackett@${username}
sleep 5
systemctl stop jackett@${username}
# Make sure .config/Jackett exists and has correct permissions.
mkdir -p /home/${username}/.config/Jackett
chmod 700 /home/${username}/.config/Jackett
chown ${username}.${username} -R /home/${username}/.config/Jackett
sed -i "s/\"AllowExternal.*/\"AllowExternal\": false,/g" /home/${username}/.config/Jackett/ServerConfig.json
sed -i "s/\"BasePathOverride.*/\"BasePathOverride\": \"\/jackett\"/g" /home/${username}/.config/Jackett/ServerConfig.json
# Disable native auto-update, since we have a command for that.
sed -i "s/\"UpdateDisabled.*/\"UpdateDisabled\": true,/g" /home/${username}/.config/Jackett/ServerConfig.json

cat > /etc/apache2/sites-enabled/jackett.conf <<EOF
<Location /jackett>
ProxyPass http://localhost:9117/jackett
ProxyPassReverse http://localhost:9117/jackett
AuthType Digest
AuthName "rutorrent"
AuthUserFile '/etc/htpasswd'
Require user ${username}
</Location>
EOF
chown www-data: /etc/apache2/sites-enabled/jackett.conf
service apache2 reload
service jackett@${username} start


echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Jackett Install Complete!" >>"${OUTTO}" 2>&1;

echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;

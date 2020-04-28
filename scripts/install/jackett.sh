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

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
else
  OUTTO="/root/logs/swizzin.log"
fi
distribution=$(lsb_release -is)
version=$(lsb_release -cs)
username=$(cut -d: -f1 < /root/.master.info)
jackett=$(curl -s https://api.github.com/repos/Jackett/Jackett/releases/latest | grep AMDx64 | grep browser_download_url | cut -d \" -f4)
#jackettver=$(wget -q https://github.com/Jackett/Jackett/releases/latest -O - | grep -E \/tag\/ | grep -v repository | awk -F "[><]" '{print $3}')
password=$(cut -d: -f2 < /root/.master.info)

echo >>"${OUTTO}" 2>&1;
echo "Installing Jackett ... " >>"${OUTTO}" 2>&1;

cd /home/$username
wget -q $jackett
tar -xvzf Jackett.Binaries.LinuxAMDx64.tar.gz > /dev/null 2>&1
rm -f Jackett.Binaries.LinuxAMDx64.tar.gz
chown ${username}.${username} -R Jackett

cat > /etc/systemd/system/jackett@.service <<JAK
[Unit]
Description=jackett for %i
After=network.target

[Service]
SyslogIdentifier=jackett.%i
Type=simple
User=%i
WorkingDirectory=/home/%i/Jackett
ExecStart=/bin/sh -c "/home/%i/Jackett/jackett_launcher.sh"
Restart=always
RestartSec=5
TimeoutStopSec=20
[Install]
WantedBy=multi-user.target
JAK

if [[ ! -f /home/${username}/Jackett/jackett_launcher.sh ]]; then
cat > /home/${username}/Jackett/jackett_launcher.sh <<'JL'
#!/bin/bash
user=$(whoami)

/home/${user}/Jackett/jackett

while pgrep -u ${user} JackettUpdater > /dev/null ; do
     sleep 1
done

echo "Jackett update complete"
JL
chmod +x /home/${username}/Jackett/jackett_launcher.sh
fi

mkdir -p /home/${username}/.config/Jackett
cat > /home/${username}/.config/Jackett/ServerConfig.json <<JSC
{
  "Port": 9117,
  "AllowExternal": true,
  "APIKey": "",
  "AdminPassword": "",
  "InstanceId": "",
  "BlackholeDir": "",
  "UpdateDisabled": false,
  "UpdatePrerelease": false,
  "BasePathOverride": "",
  "OmdbApiKey": "",
  "OmdbApiUrl": "",
  "ProxyUrl": "",
  "ProxyType": 0,
  "ProxyPort": null,
  "ProxyUsername": "",
  "ProxyPassword": "",
  "ProxyIsAnonymous": true
}
JSC

chown ${username}.${username} -R /home/${username}/.config/Jackett


if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/jackett.sh
  systemctl reload nginx
fi

systemctl enable --now jackett@${username} >/dev/null 2>&1

sleep 10

cookie=$(curl -v 127.0.0.1:9117/jackett/UI/Dashboard -L 2>&1 | grep -m1 Set-Cookie | awk '{printf $3}' | sed 's/;//g')
curl http://127.0.0.1:9117/jackett/api/v2.0/server/adminpassword -H 'Content-Type: application/json' -H 'Cookie: '${cookie}'' --data-binary '"'${password}'"'



touch /install/.jackett.lock

echo >>"${OUTTO}" 2>&1;
echo >>"${OUTTO}" 2>&1;
echo "Jackett Install Complete!" >>"${OUTTO}" 2>&1;

echo "Close this dialog box to refresh your browser" >>"${OUTTO}" 2>&1;

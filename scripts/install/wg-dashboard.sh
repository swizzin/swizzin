#! /bin/bash
# wg-dashboard installer
# Flying_sausages for swizzin 2020
# GPLv3
# Adapted from https://github.com/wg-dashboard/wg-dashboard/blob/master/install_script.sh


if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

if [[ ! -f /install/.wireguard.lock ]]; then
    echo "Please first install wireguard"
    return 1
fi

# shellcheck source=sources/functions/npm
. /etc/swizzin/sources/functions/npm
npm_install

# delete wg-dashboard folder and wg-dashboard.tar.gz to make sure it does not exist
rm -rf /opt/wg-dashboard
rm -rf /tmp/wg-dashboard.tar.gz

echo "Downloading Latest stable wg-dashboard release"
curl -L https://github.com/"$(wget https://github.com/wg-dashboard/wg-dashboard/releases/latest -O - | grep -e '/.*/.*/.*tar.gz' -o)" --output /tmp/wg-dashboard.tar.gz

mkdir /opt/wg-dashboard
tar -xzf /tmp/wg-dashboard.tar.gz --strip-components=1 -C /opt/wg-dashboard

# https://www.youtube.com/watch?v=hAKaNVtiQdU
sed -i 's/3000/3024/g' /opt/wg-dashboard

npm i --production --unsafe-perm /opt/wg-dashboard

# create service unit file
echo "[Unit]
Description=wg-dashboard service
After=network.target
[Service]
Restart=always
WorkingDirectory=/opt/wg-dashboard
ExecStart=/usr/bin/node /opt/wg-dashboard/src/server.js
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/wg-dashboard.service

# reload systemd unit files
systemctl daemon-reload
# start wg-dashboard service on reboot
systemctl enable wg-dashboard
# start wg-dashboard service
systemctl start wg-dashboard

# shellcheck source=sources/functions/coredns
. /etc/swizzin/sources/functions/coredns
_install_coredns

touch /install/.wg-dashboard.lock

if [[ -f /install/.nginx.lock ]]; then
    bash /etc/swizzin/scripts/nginx/wg-dashboard
else
    echo "You can access the dashboard through an SSH tunnel over port 3024."
    echo "e.g. ssh <destination> -L 3024:localhost:3024"
    echo "After that, visit http://localhost:3024"
fi


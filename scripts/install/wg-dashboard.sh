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
    exit 1
fi

# shellcheck source=sources/functions/npm
. /etc/swizzin/sources/functions/npm
npm_install

# delete wg-dashboard folder and wg-dashboard.tar.gz to make sure it does not exist
optdir="/opt/wg-dashboard"
tmptar="/tmp/wg-dashboard.tar.gz"
rm -rf "${optdir}"
rm -rf "${tmptar}"

echo "Downloading Latest stable wg-dashboard release"
dlurl=$(wget https://github.com/wg-dashboard/wg-dashboard/releases/latest -O - | grep -e '/.*/.*/.*tar.gz' -o)
echo "DL URL is $dlurl"
curl -L https://github.com/"$dlurl" --output "${tmptar}"

mkdir "${optdir}"
tar -xzf "${tmptar}" --strip-components=1 -C "${optdir}" -v
tar -xzf "${tmptar}" --strip-components=1 -C "${optdir}" -v

# https://www.youtube.com/watch?v=hAKaNVtiQdU
#TODO make sure to change this from 3000 becuase ombi clashes with this
# sed -i 's/3000/3024/g' "${optdir}"/src/server.js
# sed -i 's/3000/3024/g' "${optdir}"/src/dataManager.js
# sed -i 's/3000/3024/g' "${optdir}"/server_config.js

npm i --production --unsafe-perm "${optdir}"

# create service unit file
echo "[Unit]
Description=wg-dashboard service
After=network.target
[Service]
Restart=always
WorkingDirectory=${optdir}
ExecStart=/usr/bin/node ${optdir}/src/server.js
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
    bash /etc/swizzin/scripts/nginx/wg-dashboard.sh
else
    echo "You can access the dashboard through an SSH tunnel over port 3024."
    echo "e.g. ssh <destination> -L 3024:localhost:3024"
    echo "After that, visit http://localhost:3024"
fi


#TODO Create user via POST over CURL
# http://localhost:3000/api/createuser
# application/json; charset=utf-8
# {"username":"test","password":"test123","password_confirm":"test123"}

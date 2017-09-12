#! /bin/bash
# Netdata installer for swizzin
# Author: liara

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  log="/srv/panel/db/output.log"
else
  log="/dev/null"
fi

bash <(curl -Ss https://my-netdata.io/kickstart.sh) --non-interactive >> $log 2>&1

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/netdata.sh
  service nginx reload
fi

touch /install/.netdata.lock
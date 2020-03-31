#! /bin/bash
# Netdata installer for swizzin
# Author: liara

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

bash <(curl -Ss https://my-netdata.io/kickstart.sh) --non-interactive >> $log 2>&1

if [[ -f /install/.nginx.lock ]]; then
  bash /usr/local/bin/swizzin/nginx/netdata.sh
  service nginx reload
fi

touch /install/.netdata.lock
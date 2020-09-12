#! /bin/bash
# Mango deyeeter by flying_sausages 2020 for swizzin

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

rm -rf /opt/mango
systemctl disable --now mango >> $log 2>&1
rm /etc/systemd/system/mango.service
systemctl daemon-reload >> $log 2>&1

if [[ -f /install/.nginx.lock ]]; then
  rm /etc/nginx/apps/mango.conf
  systemctl reload nginx
fi

userdel mango -f -r >> $log 2>&1

rm /install/.mango.lock
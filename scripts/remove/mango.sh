#! /bin/bash
# Mango deyeeter by flying_sausages 2020 for swizzin

 

rm -rf /opt/mango
systemctl disable --now -q mango
rm /etc/systemd/system/mango.service
systemctl daemon-reload -q

if [[ -f /install/.nginx.lock ]]; then
  rm /etc/nginx/apps/mango.conf
  systemctl reload nginx
fi

userdel mango -f -r >> $log 2>&1

rm /install/.mango.lock
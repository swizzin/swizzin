#! /bin/bash
# Webmin yeeter 
# flying_sausages 2020 for swizzin

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

apt_remove webmin
rm -rf /etc/webmin
rm /etc/apt/sources.list.d/webmin.list

if [[ -f /install/.nginx.lock ]]; then 
    rm /etc/nginx/apps/webmin.conf
    systemctl reload nginx
fi

rm /install/.webmin.lock


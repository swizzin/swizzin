#!/bin/bash
# Nginx configuration for Deluge
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
users=($(cut -d: -f1 < /etc/htpasswd))

if [[ -n $1 ]]; then
  users=($1)
fi

if [[ ! -f /etc/nginx/apps/dindex.conf ]]; then
  cat > /etc/nginx/apps/dindex.conf <<DIN
location /deluge.downloads {
  alias /home/\$remote_user/torrents/deluge;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;

  location ~* \.php$ {

  } 
}
DIN
fi

for u in "${users[@]}"; do
  if [[ -f /etc/nginx/apps/${u}.dindex.conf ]]; then rm -f /etc/nginx/apps/${u}.dindex.conf; fi

  isactive=$(systemctl is-active deluge-web@$u)
  if [[ $isactive == "active" ]]; then
    systemctl stop deluge-web@$u
  fi

  sed -i 's/"interface": "0.0.0.0"/"interface": "127.0.0.1"/g' /home/$u/.config/deluge/web.conf
  sed -i 's/"https": true/"https": false/g' /home/$u/.config/deluge/web.conf

  if [[ $isactive == "active" ]]; then
    systemctl start deluge-web@$u
  fi
  
  if [[ ! -f /etc/nginx/conf.d/${u}.deluge.conf ]]; then
    DWPORT=$(grep port /home/$u/.config/deluge/web.conf | cut -d: -f2| sed 's/ //g' | sed 's/,//g')
    cat > /etc/nginx/conf.d/${u}.deluge.conf <<DUPS
upstream $u.deluge {
  server 127.0.0.1:$DWPORT;
}
DUPS
  fi

  if [[ ! -f /etc/nginx/apps/deluge.conf ]]; then
    cat > /etc/nginx/apps/deluge.conf <<'DRP'
location /deluge {
  return 301 /deluge/;
}

location /deluge/ {
  include /etc/nginx/snippets/proxy.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;
  proxy_set_header X-Deluge-Base "/deluge/";
  rewrite ^/deluge/(.*) /$1 break;
  proxy_pass http://$remote_user.deluge;
}
DRP
  fi
done
systemctl reload nginx
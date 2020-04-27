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

if [[ ! -f /etc/nginx/apps/tindex.conf ]]; then
  cat > /etc/nginx/apps/tindex.conf <<DIN
location /transmission.downloads {
  alias /home/\$remote_user/torrents/transmission;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;

  location ~* \.php$ {

  } 
}
DIN
fi

for u in "${users[@]}"; do
  if [[ -f /etc/nginx/apps/${u}.tindex.conf ]]; then rm -f /etc/nginx/apps/${u}.tindex.conf; fi

  # isactive=$(systemctl is-active transmission-web@$u)
  # if [[ $isactive == "active" ]]; then
  #   systemctl stop transmission-web@$u
  # fi

  # sed -i 's/"interface": "0.0.0.0"/"interface": "127.0.0.1"/g' /home/$u/.config/transmission/web.conf
  # sed -i 's/"https": true/"https": false/g' /home/$u/.config/transmission/web.conf

  # if [[ $isactive == "active" ]]; then
  #   systemctl start transmission-web@$u
  # fi
  
  if [[ ! -f /etc/nginx/conf.d/${u}.transmisson.conf ]]; then
    rpc_port=$(grep port /home/$u/.config/transmisson/web.conf | cut -d: -f2| sed 's/ //g' | sed 's/,//g')
    . /etc/swizzin/sources/functions/transmission 
    rpc_port=$(_get_port_from_conf rpc-port)
    cat > /etc/nginx/conf.d/${u}.transmisson.conf <<DUPS
upstream $u.transmisson {
  server 127.0.0.1:${rpc_port};
}
DUPS
  fi

  if [[ ! -f /etc/nginx/apps/transmisson.conf ]]; then
    cat > /etc/nginx/apps/transmisson.conf <<'DRP'
location /transmisson {
  return 301 /transmisson/;
}

location /transmisson/ {
  include /etc/nginx/snippets/proxy.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;
  proxy_set_header X-Deluge-Base "/transmisson/";
  rewrite ^/transmisson/(.*) /$1 break;
  proxy_pass http://$remote_user.transmisson;
}
DRP
  fi
done
systemctl reload nginx
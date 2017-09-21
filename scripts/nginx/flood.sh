#!/bin/bash
# nginx configuration for flood
# Author: liara

users=($(cat /etc/htpasswd | cut -d ":" -f 1))

if [[ ! -f /etc/nginx/apps/flood.conf ]]; then
  cat > /etc/nginx/apps/flood.conf <<'FLO'
location /flood {
  return 301 /flood/;
}

location /flood/ {
  include /etc/nginx/snippets/proxy.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;
  proxy_pass http://$remote_user.flood;
  rewrite ^/flood/(.*) /$1 break;
}
FLO
fi

if [[ ! -f /etc/nginx/apps/rindex.conf ]]; then
  cat > /etc/nginx/apps/rindex.conf <<RIN
location /rtorrent.downloads {
  alias /home/\$remote_user/torrents/rtorrent;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;
}
RIN
fi

for u in "${users[@]}"; do
  if [[ ! -f /etc/nginx/conf.d/$u.flood.conf ]]; then
  port=$(grep floodServerPort /home/$u/.flood/config.js | cut -d: -f2 | sed 's/[^0-9]*//g')
  cat > /etc/nginx/conf.d/$u.flood.conf <<FLUP
upstream $u.flood {
  server 127.0.0.1:$port;
}
FLUP
  fi
  sed -i "s/floodServerHost: '0.0.0.0'/floodServerHost: '127.0.0.1'/g" /home/$u/.flood/config.js
  sed -i "s/baseURI: '\/'/baseURI: '\/flood'/g" /home/$u/.flood/config.js

  systemctl restart flood@$u
done
systemctl reload nginx
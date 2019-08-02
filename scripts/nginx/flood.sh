#!/bin/bash
# nginx configuration for flood
# Author: liara

if [[ -f /tmp/.install.lock ]]; then
  log="/root/logs/install.log"
elif [[ -f /install/.panel.lock ]]; then
  log="/srv/panel/db/output.log"
else
  log="/dev/null"
fi

users=($(cut -d: -f1 < /etc/htpasswd))
if [[ -n $1 ]]; then
	users=($1)
fi

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
  isactive=$(systemctl is-active flood@$u)
  if [[ ! -f /etc/nginx/conf.d/$u.flood.conf ]]; then
  port=$(grep floodServerPort /home/$u/.flood/config.js | cut -d: -f2 | sed 's/[^0-9]*//g')
  cat > /etc/nginx/conf.d/$u.flood.conf <<FLUP
upstream $u.flood {
  server 127.0.0.1:$port;
}
FLUP
  fi
  
  sed -i "s/floodServerHost: '0.0.0.0'/floodServerHost: '127.0.0.1'/g" /home/$u/.flood/config.js
  base=$(grep baseURI /home/$u/.flood/config.js | cut -d"'" -f2)
  sed -i "s/baseURI: '\/'/baseURI: '\/flood'/g" /home/$u/.flood/config.js

  if [[ ! -d /home/$u/.flood/server/assets ]]; then
    su - $u -c "cd /home/$u/.flood; npm run build" >> $log 2>&1
  elif [[ -d /home/$u/.flood/server/assets ]] && [[ $base == "/" ]]; then
    su - $u -c "cd /home/$u/.flood; npm run build" >> $log 2>&1
  fi

  if [[ ! -f /etc/nginx/apps/${u}.scgi.conf ]]; then
    cat > /etc/nginx/apps/${u}.scgi.conf <<RUC
location /${u} {
include scgi_params;
scgi_pass unix:/var/run/${u}/.rtorrent.sock;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd.d/htpasswd.${u};
}
RUC
  fi

  if [[ $isactive == "active" ]]; then
    systemctl restart flood@$u
  fi

done
systemctl reload nginx
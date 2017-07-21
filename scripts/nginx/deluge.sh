#!/bin/bash
users=($(cat /etc/htpasswd | cut -d ":" -f 1))

for u in "${users[@]}"; do
  if [[ ! -f /etc/nginx/apps/dindex.${u}.conf ]]; then
  cat > /etc/nginx/apps/dindex.${u}.conf <<DIN
location /${u}.deluge.downloads {
  alias /home/${u}/torrents/deluge;
  fancyindex on;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${u};
}
DIN
  fi
done
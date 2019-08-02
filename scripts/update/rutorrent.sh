#!/bin/bash

#Update club-QuickBox with latest changes
if [[ -d /srv/rutorrent/plugins/theme/themes/club-QuickBox ]]; then
  cd /srv/rutorrent/plugins/theme/themes/club-QuickBox
  git reset HEAD --hard
  git pull
fi

if [[ -d /srv/rutorrent/plugins/theme/themes/DarkBetter ]]; then
  if [[ -z "$(ls -A /srv/rutorrent/plugins/theme/themes/DarkBetter/)" ]]; then
    cd /srv/rutorrent
    git submodule update --init --recursive > /dev/null 2>&1
  fi
fi

if [[ -f /install/.flood.lock ]]; then
  users=($(cut -d: -f1 < /etc/htpasswd))
  for u in ${users[@]}; do
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
  done
  systemctl reload nginx
fi
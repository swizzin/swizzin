#!/bin/bash
users=($(cat /etc/htpasswd | cut -d ":" -f 1))
    cd /srv/rutorrent/plugins/
    git clone https://github.com/autodl-community/autodl-rutorrent.git autodl-irssi >/dev/null 2>&1 || (echo "git of autodl plugin to main plugins seems to have failed ... ")
    chown -R www-data:www-data autodl-irssi/
for u in "${users[@]}"; do
if [[ -f /install/.autodl.lock ]]; then
    IRSSI_PORT=$(cat /home/${u}/.autodl2.cfg | grep port | cut -d= -f2 | sed 's/ //g' )
    IRSSI_PASS=$(cat /home/${u}/.autodl2.cfg | grep password | cut -d= -f2 | sed 's/ //g' )
    sed -i '/?>/d' /srv/rutorrent/conf/users/${u}/config.php
    echo "\$autodlPort = \"$IRSSI_PORT\";" >> /srv/rutorrent/conf/users/${u}/config.php
    echo "\$autodlPassword = $IRSSI_PASS;" >> /srv/rutorrent/conf/users/${u}/config.php
    echo "?>" >> /srv/rutorrent/conf/users/${u}/config.php
  fi
done

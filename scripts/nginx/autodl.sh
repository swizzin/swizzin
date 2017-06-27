#!/bin/bash
users=($(cat /etc/htpasswd | cut -d ":" -f 1))

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

#!/bin/bash
# Nginx Configuration for Autodl
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
users=($(cut -d: -f1 < /etc/htpasswd))
if [[ -f /install/.rutorrent.lock ]]; then
    cd /srv/rutorrent/plugins/
    if [[ ! -d /srv/rutorrent/plugins/autodl-irssi ]]; then
        git clone https://github.com/swizzin/autodl-rutorrent.git autodl-irssi >> ${log} 2>&1 || { echo_error "git of autodl plugin to main plugins seems to have failed"; }
        chown -R www-data:www-data autodl-irssi/
    fi
    for u in "${users[@]}"; do
        IRSSI_PORT=$(grep gui-server-port /home/${u}/.autodl/autodl.cfg | cut -d= -f2 | sed 's/ //g')
        IRSSI_PASS=$(grep gui-server-password /home/${u}/.autodl/autodl.cfg | cut -d= -f2 | sed 's/ //g')
        if [[ -z $(grep autodl /srv/rutorrent/conf/users/${u}/config.php) ]]; then
            sed -i '/?>/d' /srv/rutorrent/conf/users/${u}/config.php
            sed -i '/autodl/d' /srv/rutorrent/conf/users/${u}/config.php
            echo "\$autodlPort = \"$IRSSI_PORT\";" >> /srv/rutorrent/conf/users/${u}/config.php
            echo "\$autodlPassword = \"$IRSSI_PASS\";" >> /srv/rutorrent/conf/users/${u}/config.php
            echo "?>" >> /srv/rutorrent/conf/users/${u}/config.php
        fi
    done
fi

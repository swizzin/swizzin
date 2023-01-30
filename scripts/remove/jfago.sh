#!/bin/bash

systemctl disable --now jfago -q

rm -rf /root/.config/jfa-go

apt_remove jfa-go

rm -f /usr/share/keyrings/jf-ago-archive-keyring.gpg
rm -f /etc/apt/sources.list.d/jf-ago.list

apt_update

rm -f /etc/systemd/system/jfago.service

systemctl daemon-reload -q

if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/jfago.conf
    systemctl reload nginx
fi

rm /install/.jfago.lock

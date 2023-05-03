#!/bin/bash

systemctl stop -q nginx

[[ $(_os_codename) =~ ^(focal|buster|bullseye)$ ]] && geoip="php-geoip" || geoip=""
APT="nginx-extras nginx libnginx-mod-http-fancyindex ssl-cert php php-cli php-fpm php-dev php-xml php-curl php-xmlrpc php-json php-opcache ${geoip}"
apt_remove $APT

LIST='nginx-* php7.0-* php-*'
apt_remove --purge $LIST

rm -rf /etc/nginx
rm -rf /etc/php

. /etc/swizzin/sources/functions/utils
rm_if_exists "/srv/rutorrent"
rm_if_exists "/install/.rutorrent.lock"

rm_if_exists "/srv/panel"
rm_if_exists "/etc/sudoers.d/panel"
rm_if_exists "/etc/cron.d/set_interface"

# rm_if_exists "/srv/organizr"
rm_if_exists "/install/.organizr.lock"

rm /install/.nginx.lock

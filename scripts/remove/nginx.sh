#!/bin/bash

systemctl stop nginx

APT='nginx-extras nginx libnginx-mod-http-fancyindex ssl-cert php7.0 php7.0-cli php7.0-fpm php7.0-dev php7.0-xml php7.0-curl php7.0-xmlrpc php7.0-json php7.0-mcrypt php7.0-opcache php-geoip php-xml php php-cli php-fpm php-dev php-xml php-curl php-xmlrpc php-json php-mcrypt php-opcache'
for depends in $APT; do
apt-get -y -q remove "$depends" >/dev/null 2>&1
done

LIST='nginx-* php7.0-* php-*'
for package in $LIST; do
    apt-get -y -q purge ${package} >/dev/null 2>&1
done
apt-get -y -q autoremove >/dev/null 2>&1

rm -rf /etc/nginx
rm -rf /etc/php

. /etc/swizzin/sources/functions/utils
rm_if_exists "/srv/rutorrent"
rm_if_exists "/srv/panel"
rm_if_exists "/etc/sudoers.d/panel"
rm_if_exists "/etc/cron.d/set_interface"
rm_if_exists "/install/.rutorrent.lock"

rm /install/.nginx.lock
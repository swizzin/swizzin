#!/bin/bash

systemctl stop nginx

APT='nginx-extras ssl-cert php7.0 php7.0-cli php7.0-fpm php7.0-dev php7.0-xml php7.0-curl php7.0-xmlrpc php7.0-json php7.0-mcrypt php7.0-opcache php-geoip php-xml php php-cli php-fpm php-dev php-xml php-curl php-xmlrpc php-json php-mcrypt php-opcache'
for depends in $APT; do
apt-get -qq -y --yes --force-yes remove "$depends" >/dev/null 2>&1
done

apt-get -y -q purge nginx-* php7.0-* >/dev/null 2>&1

rm -rf /etc/nginx
rm -rf /etc/php

if [[ -d /srv/panel ]]; then
    rm -rf /srv/panel
    /etc/sudoers.d/panel
    rm /etc/cron.d/set_interface
fi

if [[ -d /srv/rutorrent ]]; then
    rm -rf /srv/rutorrent
fi
rm /install/.panel.lock
rm /install/.nginx.lock
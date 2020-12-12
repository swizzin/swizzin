#!/bin/bash
# ruTorrent installation and nginx configuration
# Author: flying_sausages
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "nginx does not appear to be installed, ruTorrent requires a webserver to function. Please install nginx first before installing this package."
    exit 1
fi
#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php

###################################

phpv=$(php_service_version)
sock="php${phpv}-fpm"

cat > /etc/nginx/apps/organizr.conf << ORGNGINX
location /organizr {
  root /srv;
  index index.php;
  try_files \$uri \$uri/ =404;

  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/$sock.sock;
    fastcgi_param SCRIPT_FILENAME /srv\$fastcgi_script_name;
    fastcgi_buffers 32 32k;
    fastcgi_buffer_size 32k;
  }

  location /organizr/api/v2 {
    try_files \$uri /organizr/api/v2/index.php\$is_args\$args;
  }
}
ORGNGINX

# blacklist_path="/etc/php/$phpv/opcache-blacklist.txt"

# if [[ ! -f $blacklist_path ]]; then
#   touch "$blacklist_path"
# fi
# echo "/srv/organizr/*" >> "$blacklist_path"
# echo "opcache.blacklist_filename=$blacklist_path" >> /etc/php/$phpv/fpm/php.ini

reload_php_fpm

chown -R www-data:www-data /srv/organizr
systemctl reload nginx

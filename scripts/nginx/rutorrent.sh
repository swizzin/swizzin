#!/bin/bash
# ruTorrent installation and nginx configuration
# Author: liara
# Copyright (C) 2017 Swizzin
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
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/rtorrent
. /etc/swizzin/sources/functions/rutorrent

if [[ ! -f /install/.rutorrent.lock ]]; then
    rutorrent_install
fi
rutorrent_nginx_config
rutorrent_user_config

restart_php_fpm
chown -R www-data:www-data /srv/rutorrent
echo_progress_start "Reloading nginx"
systemctl reload nginx >> $log 2>&1
echo_progress_done
touch /install/.rutorrent.lock

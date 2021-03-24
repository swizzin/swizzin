#!/bin/bash
# Nginx Configuration for Emby
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
if [[ ! -f /etc/nginx/apps/emby.conf ]]; then
    cat > /etc/nginx/apps/emby.conf << EMB
location /emby/ {
  rewrite /emby/(.*) /\$1 break;
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:8096/;
}
EMB
fi

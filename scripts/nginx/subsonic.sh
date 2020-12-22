#!/bin/bash
# Nginx Configuration for Subsonic
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
MASTER=$(cut -d: -f1 < /root/.master.info)

if [[ ! -f /etc/nginx/apps/subsonic.conf ]]; then
    cat > /etc/nginx/apps/subsonic.conf << SUB
location /subsonic {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass              http://127.0.0.1:4040;
}
SUB
fi
sed -i 's/SUBSONIC_HOST=0.0.0.0/SUBSONIC_HOST=127.0.0.1/g' /usr/share/subsonic/subsonic.sh
sed -i 's/SUBSONIC_CONTEXT_PATH=\//SUBSONIC_CONTEXT_PATH=\/subsonic/g' /usr/share/subsonic/subsonic.sh
systemctl try-restart subsonic

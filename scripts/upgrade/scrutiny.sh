#!/bin/bash

if [[ ! -f /install/.scrutiny.lock ]]; then
    echo "Scurtiny doesn't appear to be installed. What do you hope to accomplish by running this script?"
    exit 1
fi

#TODO make a backup before? not sure if there will be any persistent data, could move it somewhere else

systemctl stop -q scrutiny-web

#shellcheck source=sources/functions/scrutiny
. /etc/swizzin/sources/functions/scrutiny
_download_scrutiny

systemctl restart -q scrutiny-web

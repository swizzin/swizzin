#!/bin/bash

if [[ ! -f /install/.scrutiny.lock ]]; then
    echo "Scurtiny doesn't appear to be installed. What do you hope to accomplish by running this script?"
    exit 1
fi

scrutinydir="/opt/scrutiny"

#TODO make a backup before? not sure if there will be any persistent data, could move it somewhere else

systemctl stop -q scrutiny-web

#shellcheck source=sources/functions/scrutiny
. /etc/swizzin/sources/functions/scrutiny
case "$(_os_arch)" in
    "amd64") arch='amd64' ;;
    "arm64") arch="arm64" ;;
    "armhf") arch="arm-6" ;;
    *)
        echo_error "Arch not supported"
        exit 1
        ;;
esac
_download_scrutiny "$arch"

systemctl restart -q scrutiny-web

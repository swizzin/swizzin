#!/bin/bash

#TODO shut up and make
if [[ -e /usr/bin/calibre-uninstall ]]; then
    /usr/bin/calibre-uninstall
else
    apt_remove calibre
fi

systemctl disable --now -q calibre-cs
rm /etc/systemd/system/calibre-cs.service

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
master=$(_get_master_username)
rm -rf "/home/$master/.config/calibre"
rm /install/.calibre.lock

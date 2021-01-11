#!/bin/bash

# Some systems could be apt-installed, some will have script/built setup
if [[ -e /usr/bin/calibre-uninstall ]]; then
    #TODO shut up and make this go unattended
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

#!/bin/bash

# Some systems could be apt-installed, some will have script/built setup
if [[ -e /usr/bin/calibre-uninstall ]]; then
    #TODO shut up and make this go unattended
    /usr/bin/calibre-uninstall
else
    apt_remove calibre
fi

if [ -f /install/.calibre-cs.lock ]; then
    bash /etc/swizzin/scripts/remove/calibre-cs.sh
fi

rm /install/.calibre.lock

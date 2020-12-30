#!/bin/bash

if islocked "znc"; then
    . /etc/swizzin/sources/functions/letsencrypt
    le_znc_hook
    if ! getlockinfo "znc"; then
        echo "$(grep Port /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" | setlockinfo "znc"
        echo "$(grep SSL /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" | setlockinfo "znc"
    fi
fi

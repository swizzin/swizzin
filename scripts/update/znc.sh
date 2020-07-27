#!/bin/bash

if [[ -f /install/.znc.lock ]]; then
    . /etc/swizzin/sources/functions/letsencrypt
    le_znc_hook
    if [[ ! -s /install/.znc.lock ]]; then
        echo "$(grep Port /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" > /install/.znc.lock
        echo "$(grep SSL /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" >> /install/.znc.lock
    fi
fi
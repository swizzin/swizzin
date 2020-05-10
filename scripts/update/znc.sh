#!/bin/bash

if [[ -f /install/.znc.lock ]]; then
    if [[ ! -s /install/.znc.lock ]]; then
        echo "$(grep Port /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" > /install/.znc.lock
        echo "$(grep SSL /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" >> /install/.znc.lock
    fi
fi
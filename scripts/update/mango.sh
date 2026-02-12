#!/bin/bash

#If the user tried to upgrade mango before the issue got fixed, the binary was downloaded to the / dir and nothing got refreshed.
if [[ -f /mango ]]; then
    rm /mango
fi

#If this file existed, delete it
if [[ -f /root/mango.info ]]; then
    rm /root/mango.info
fi

if [[ -f /install/.mango.lock ]]; then
    echo_warn "Mango is no longer supported. Please uninstall it using 'box remove mango'"
fi

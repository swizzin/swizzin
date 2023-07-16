#!/bin/bash

users=($(cut -d: -f1 < /etc/htpasswd))

for u in "${users[@]}"; do
    #autodl2.cfg has been deprecated
    if [[ -f /home/${u}/.autodl/autodl2.cfg ]]; then
        echo_progress_start "Updating autodl.cfg for ${u}"
        mv "/home/${u}/.autodl/autodl.cfg" "/home/${u}/.autodl/autodl.bak"
        mv "/home/${u}/.autodl/autodl2.cfg" "/home/${u}/.autodl/autodl.cfg"
        cat "/home/${u}/.autodl/autodl.bak" >> "/home/${u}/.autodl/autodl.cfg"
        rm "/home/${u}/.autodl/autodl.bak"
        chown -R $u: /home/${u}/.autodl/
        chown -R $u: /home/${u}/.irssi/
        echo_progress_done
    fi
done

if [[ -f /install/.nginx.lock ]]; then
    /usr/local/bin/swizzin/php-fpm-cli -r 'opcache_reset();'
fi

#!/bin/bash

if [[ -f /install/.quota.lock ]]; then
    if [[ ! -f /etc/sudoers.d/quota ]]; then
        cat > /etc/sudoers.d/quota << EOSUD
#Defaults  env_keep -="HOME"
Defaults:www-data !logfile
Defaults:www-data !syslog
Defaults:www-data !pam_session

Cmnd_Alias   QUOTA = /usr/bin/quota

www-data     ALL = (ALL) NOPASSWD: QUOTA
EOSUD
    fi
fi

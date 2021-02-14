#!/usr/bin/env bash

#Install logrotate definition for swizzin if it does not exist
if [ -d /root/logs ]; then
    echo_warn "Please note that swizzin logs are being permanently moved to /var/log/swizzin"
    mv /root/logs/swizzin.log /root/logs/swizzin.log.1
    mv /root/logs /var/log/swizzin
fi

if [ ! -e "/etc/logrotate.d/swizzin" ]; then
    #shellcheck source=sources/functions/logrotate
    . /etc/swizzin/sources/functions/logrotate
    install_swiz_logrotate
fi

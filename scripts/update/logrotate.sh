#!/usr/bin/env bash

#Install logrotate definition for swizzin if it does not exist
if [ ! -e "/etc/logrotate.d/swizzin" ]; then
    #shellcheck source=sources/functions/logrotate
    . /etc/swizzin/sources/functions/logrotate
    install_logrotate
fi

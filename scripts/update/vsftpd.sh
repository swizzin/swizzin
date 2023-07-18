#!/usr/bin/env bash
if [[ -f /install/.vsftpd.lock ]]; then
    #shellcheck source=sources/functions/letsencrypt
    . /etc/swizzin/sources/functions/letsencrypt
    le_vsftpd_hook
fi

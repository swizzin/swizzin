#!/usr/bin/env bash
if [[ -f /install/.vsftpd.lock ]]; then
    #shellcheck source=sources/functions/letsencrypt
    . /etc/swizzin/sources/functions/letsencrypt
    if grep -q ".ts.net" "/etc/nginx/sites-enabled/default"; then
        _ts_vsftpd_hook
    else
        le_vsftpd_hook
    fi
fi

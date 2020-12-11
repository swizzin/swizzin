#!/bin/bash

find /home -mindepth 1 -maxdepth 1 -type d -exec chmod 750 {} \;

if [[ -f /install/.plex.lock ]]; then
    master=$(cut -d: -f1 < /root/.master.info)
    if ! groups plex | grep -q "${master}"; then
        echo_log_only "Adding plex to master group"
        usermod -a -G "${master}" plex
    fi
fi

#shellcheck disable=SC2016
if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.profile; then
    sed -i '/export PATH=$PATH:\/usr\/local\/bin\/swizzin/d' /root/.profile
fi

#shellcheck disable=SC2016
if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.bashrc; then
    :
else
    echo 'export PATH=$PATH:/usr/local/bin/swizzin' >> /root/.bashrc
fi

#!/bin/bash

find /home -mindepth 1 -maxdepth 1 -type d -exec chmod 750 {} \;
master=$(cut -d: -f1 < /root/.master.info)
if [[ -f /install/.plex.lock ]]; then
    if [[ -z $(groups plex | grep ${master}) ]]; then
        usermod -a -G ${master} plex
    fi
fi

if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.profile; then
    sed -i '/export PATH=$PATH:\/usr\/local\/bin\/swizzin/d' /root/.profile
fi

if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.bashrc; then
    :
else
    echo 'export PATH=$PATH:/usr/local/bin/swizzin' >> /root/.bashrc
fi

# Ensure .config dir is correctly owned
if [[ -e /home/${master}/.config ]]; then
    perm=$(stat -c '%U' /home/"${master}"/.config)
    if [[ ! $perm == ${master} ]]; then
        chown -R "${master}": /home/"${master}"/.config
    fi
fi

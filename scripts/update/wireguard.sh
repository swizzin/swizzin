#!/bin/bash

if [[ -f /install/.wireguard.lock ]]; then
    distribution=$(lsb_release -is)
    #Fix potential wireguard repo issues under Debian
    if [[ $distribution == "Debian" ]]; then
        if grep -q "Pin-Priority: 150" /etc/apt/preferences.d/limit-unstable 2> /dev/null; then
            . /etc/swizzin/sources/functions/backports
            check_debian_backports
            rm /etc/apt/sources.list.d/unstable.list
            rm /etc/apt/preferences.d/limit-unstable
            apt_update
            # echo "Ensuring correct wireguard packages are installed"
            #This apt command must be called directly because we are overriding the currently installed unstable package to buster-backports
            apt-get -y --allow-downgrades install wireguard/buster-backports wireguard-tools/buster-backports wireguard-dkms/buster-backports >> ${log} 2>&1
        fi
    fi
fi

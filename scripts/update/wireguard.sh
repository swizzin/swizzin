#!/bin/bash

if [[ -f /install/.wireguard.lock ]]; then
    distribution=$(lsb_release -is)
    codename=$(lsb_release -cs)
    if [[ -z $log ]]; then log=/root/logs/swizzin.log; fi
    #Fix potential wireguard repo issues under Debian
    if [[ $distribution == "Debian" ]]; then
        if grep -q "Pin-Priority: 150" /etc/apt/preferences.d/limit-unstable 2> /dev/null; then
            if [[ ! $codename == "stretch" ]]; then
                . /etc/swizzin/sources/functions/backports
                check_debian_backports
                rm /etc/apt/sources.list.d/unstable.list
                rm /etc/apt/preferences.d/limit-unstable
                apt_update
                echo "Ensuring correct wireguard packages are installed"
                #This apt command must be called directly because we are overriding the currently installed unstable package to buster-backports
                apt-get -y --allow-downgrades install wireguard/buster-backports wireguard-tools/buster-backports wireguard-dkms/buster-backports >> ${log} 2>&1
            else
                echo "Adjusting unstable pin-priority to avoid unwanted packages"
                printf 'Package: *\nPin: release a=unstable\nPin-Priority: 10\n\nPackage: *\nPin: release a=stretch-backports\nPin-Priority: 250' > /etc/apt/preferences.d/limit-unstable
            fi
        fi
    elif [[ $codename =~ ("xenial"|"bionic") ]]; then
        if grep -h "wireguard/wireguard" /etc/apt/sources.list{,.d/*} | grep -q -v -P '^#'; then
            echo "Downgrading wireguard from PPA status to mainline"
            apt-add-repository -y ppa:wireguard/wireguard --remove
            apt_remove wireguard
            apt_autoremove
            apt_install wireguard
        fi
        
    fi
fi
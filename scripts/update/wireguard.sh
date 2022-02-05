#!/bin/bash

if [[ -f /install/.wireguard.lock ]]; then
    distribution=$(lsb_release -is)
    codename=$(lsb_release -cs)
    #Fix potential wireguard repo issues under Debian
    if [[ $distribution == "Debian" ]]; then
        if grep -q "Pin-Priority: 150" /etc/apt/preferences.d/limit-unstable 2> /dev/null; then
            if [[ ! $codename == "stretch" ]]; then
                . /etc/swizzin/sources/functions/backports
                check_debian_backports
                rm /etc/apt/sources.list.d/unstable.list
                rm /etc/apt/preferences.d/limit-unstable
                apt_update
                # echo "Ensuring correct wireguard packages are installed"
                #This apt command must be called directly because we are overriding the currently installed unstable package to buster-backports
                apt-get -y --allow-downgrades install wireguard/buster-backports wireguard-tools/buster-backports wireguard-dkms/buster-backports >> ${log} 2>&1
            else
                echo_info "Adjusting unstable pin-priority to avoid unwanted packages"
                printf 'Package: *\nPin: release a=unstable\nPin-Priority: 10\n\nPackage: *\nPin: release a=stretch-backports\nPin-Priority: 250' > /etc/apt/preferences.d/limit-unstable
            fi
        fi
    elif [[ $codename == "bionic" ]]; then
        if grep -q "wireguard/wireguard" /etc/apt/sources.list{,.d/*}; then
            echo_info "Downgrading wireguard from PPA status to mainline"
            filenames=($(grep -l "wireguard/wireguard" /etc/apt/sources.list{,.d/*}))
            for file in "${filenames[@]}"; do
                if [[ "$file" =~ sources\.list$ ]]; then
                    sed -i '/wireguard\/wireguard/d' "${file}"
                elif [[ "$file" =~ sources\.list\.d ]]; then
                    rm -f "${file}"
                fi
            done
            apt_remove wireguard
            apt_autoremove
            apt_install wireguard
        fi

    fi
fi

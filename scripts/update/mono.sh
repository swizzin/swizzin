#!/bin/bash
#Have I mentioned I hate mono?

if [[ -f /install/.sonarr.lock ]]; then
    #Check if mono needs an update
    . /etc/swizzin/sources/functions/mono
    mono_repo_update
    systemctl try-restart sonarr

    #Ensure Sonarr repo key is up-to-date
    if ! apt-key adv --list-public-keys 2> /dev/null | grep -q A236C58F409091A18ACA53CBEBFF6B99D9B78493 >> $log 2>&1; then
        distribution=$(_os_distro)
        if [[ $distribution == "ubuntu" ]]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493 > /dev/null 2>&1
        elif [[ $distribution == "debian" ]]; then
            #buster friendly
            apt-key --keyring /etc/apt/trusted.gpg.d/nzbdrone.gpg adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xA236C58F409091A18ACA53CBEBFF6B99D9B78493
        fi
    fi
fi

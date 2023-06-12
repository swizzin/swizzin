#!/bin/bash
# Ensures that dependencies are installed and corrects them if that is not the case.

if ! which add-apt-repository > /dev/null; then
    apt_install software-properties-common # Ubuntu may require universe/mutliverse enabled for certain packages so we must ensure repos are enabled before deps are attempted to installed
fi

if [[ $(_os_distro) == "ubuntu" ]]; then
    if [[ $(_os_codename) == "jammy" ]]; then
        if ! grep 'ubuntu-toolchain-r' /etc/apt/sources.list.d/ubuntu-toolchain-r-ubuntu-ppa-jammy.list | grep -q -v '^#'; then
            echo_info "Adding toolchain repo"
            add-apt-repository -y ppa:ubuntu-toolchain-r/ppa >> ${log} 2>&1
            trigger_apt_update=true
        fi
    fi
    #Ignore a found match if the line is commented out
    if ! grep 'universe' /etc/apt/sources.list | grep -q -v '^#'; then
        echo_info "Enabling universe repo"
        add-apt-repository universe >> ${log} 2>&1
        trigger_apt_update=true
    fi
    if ! grep 'multiverse' /etc/apt/sources.list | grep -q -v '^#'; then
        echo_info "Enabling multiverse repo"
        add-apt-repository multiverse >> ${log} 2>&1
        trigger_apt_update=true
    fi
    if ! grep 'restricted' /etc/apt/sources.list | grep -q -v '^#'; then
        echo_info "Enabling restricted repo"
        add-apt-repository restricted >> ${log} 2>&1
        trigger_apt_update=true
    fi
elif [[ $(_os_distro) == "debian" ]]; then
    if ! grep contrib /etc/apt/sources.list | grep -q -v '^#'; then
        echo_info "Enabling contrib repo"
        apt-add-repository contrib >> ${log} 2>&1
        trigger_apt_update=true
    fi
    if ! grep non-free /etc/apt/sources.list | grep -q -v '^#'; then
        echo_info "Enabling non-free repo"
        apt-add-repository non-free >> ${log} 2>&1
        trigger_apt_update=true
    fi
fi
if [[ $trigger_apt_update == "true" ]]; then
    apt_update
fi

#space-separated list of required GLOBAL SWIZZIN dependencies (NOT application specific ones)
dependencies="whiptail git sudo curl wget lsof fail2ban apache2-utils vnstat tcl tcl-dev build-essential dirmngr apt-transport-https bc uuid-runtime jq net-tools gnupg2 cracklib-runtime unzip ccze"

apt_install "${dependencies[@]}"

. /etc/swizzin/sources/functions/gcc
GCC_Jammy_Upgrade

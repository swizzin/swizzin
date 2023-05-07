#!/bin/bash
# Ensures that dependencies are installed and corrects them if that is not the case.

if ! which add-apt-repository > /dev/null; then
    apt_install software-properties-common # Ubuntu may require universe/mutliverse enabled for certain packages so we must ensure repos are enabled before deps are attempted to installed
fi

if [[ $(_os_distro) == "ubuntu" ]]; then
    if ! which python3.11 > /dev/null; then
        echo_info "Upgrading to Python 3.11"
        add-apt-repository -y ppa:deadsnakes/ppa >> ${log} 2>&1
        apt_install python3.11-full
        echo "alias python=/usr/bin/python3.11" >> ~/.bashrc
        echo "alias python3=/usr/bin/python3.11" >> ~/.bashrc
        ln -s /usr/lib/python3.11/dist-packages/$(ls -a | grep apt_pkg.cpython) /usr/lib/python3.11/dist-packages/apt_pkg.so >> ${log} 2>&1
        source ~/.bashrc
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

#fix pip for python 3.11 after installing curl
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 >> ${log} 2>&1

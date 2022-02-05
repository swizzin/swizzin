#!/bin/bash
#
# Quassel Installer
#
# Originally written for QuickBox.io. Ported to Swizzin
# Author: liara
#
# QuickBox Copyright (C) 2016
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

distribution=$(lsb_release -is)
codename=$(lsb_release -cs)
IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')
user=$(cut -d: -f1 < /root/.master.info)

if [[ $distribution == Ubuntu ]]; then
    if [[ $codename == "bionic" ]]; then
        echo_progress_start "Installing Quassel PPA"
        apt_install software-properties-common
        apt-add-repository ppa:mamarley/quassel -y >> "$log" 2>&1
        apt_update
        echo_progress_done
    fi
    apt_install quassel-core
else
    #shellcheck source=sources/functions/backports
    . /etc/swizzin/sources/functions/backports
    if [[ $codename == "buster" ]]; then
        apt_install quassel-core
    elif [[ $codename == "stretch" ]]; then
        check_debian_backports
        echo_info "Using latest backport"
        set_packages_to_backports quassel-core
        apt_install quassel-core
    else
        echo_info "Using latest backport"
        wget -r -l1 --no-parent --no-directories -A "quassel-core*.deb" https://iskrembilen.com/quassel-packages-debian/ >> "$log" 2>&1
        echo_progress_start "Installing quassel dpkg"
        dpkg -i quassel-core* >> "$log" 2>&1
        echo_progress_done "Quassel installed"
        rm quassel-core*
        #Note: this is here due to the dependencies not being installed for the dpkg-installed package
        apt-get install -f -y -q >> "$log" 2>&1
    fi
fi
echo_progress_start "Starting quassel"
mv /etc/init.d/quasselcore /etc/init.d/quasselcore.BAK
systemctl enable -q --now quasselcore 2>&1 | tee -a $log
echo_progress_done

echo_success "Quassel installed"
echo_info "Please install quassel-client on your personal computer and connect to the newly created core at ${IP}:4242 to set up your account"

touch /install/.quassel.lock

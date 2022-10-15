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

codename=$(_os_codename)
IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

case $codename in
    bionic | focal)
        echo_progress_start "Installing Quassel PPA"
        apt_install software-properties-common
        apt-add-repository ppa:mamarley/quassel -y >> "$log" 2>&1
        apt_update
        echo_progress_done
        ;;
    stretch)
        . /etc/swizzin/sources/functions/backports
        check_debian_backports
        echo_info "Using latest backport"
        set_packages_to_backports quassel-core
        ;;
    *) ;;
esac

apt_install quassel-core

echo_progress_start "Starting quassel"
mv /etc/init.d/quasselcore /etc/init.d/quasselcore.BAK
systemctl enable -q --now quasselcore >> ${log} 2>&1
echo_progress_done

echo_success "Quassel installed"
echo_info "Please install quassel-client on your personal computer and connect to the newly created core at ${IP}:4242 to set up your account"

touch /install/.quassel.lock

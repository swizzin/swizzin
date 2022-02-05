#!/bin/bash
#
# [Quick Box :: Install Rapidleech package]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | JMSolo
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "Web server not detected. Please install nginx and restart panel install."
    exit 1
fi
MASTER=$(cut -d: -f1 < /root/.master.info)

function _installRapidleech1() {
    echo_progress_start "Cloning rapidleech"
    git clone https://github.com/Th3-822/rapidleech.git /home/"${MASTER}"/rapidleech >> $log 2>&1
    chown "${MASTER}":"${MASTER}" -R /home/"${MASTER}"/rapidleech
    echo_progress_done
}

function _installRapidleech3() {
    # Checking for nginx is the first thing the script does
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/rapidleech.sh
    systemctl reload nginx
    echo_progress_done
}

function _installRapidleech5() {
    touch /install/.rapidleech.lock
    echo_success "Rapidleech installed"
}

_installRapidleech1
_installRapidleech3
_installRapidleech5

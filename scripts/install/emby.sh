#!/bin/bash
#
# [Swizzin :: Install Emby package]
#
# Author: liara
#
# swizzin Copyright (C) 2019 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

. /etc/swizzin/sources/functions/utils

if [[ $(systemctl is-active jellyfin) == "active" ]]; then
    active=jellyfin
fi

if [[ -n $active ]]; then
    echo_info "Jellyfin and Emby cannot be active at the same time.\nDo you want to disable $active and continue with the installation?\nDon't worry, your install will remain"
    if ask "Do you want to disable $active?" Y; then
        disable=yes
    fi
    if [[ $disable == "yes" ]]; then
        echo_progress_start "Disabling service"
        systemctl disable -q --now ${active} >> ${log} 2>&1
        echo_progress_done
    else
        exit 1
    fi
fi

username=$(cut -d: -f1 < /root/.master.info)

echo_progress_start "Downloading emby installer"
current=$(github_latest_version MediaBrowser/Emby.Releases)
wget -O /tmp/emby.dpkg https://github.com/MediaBrowser/Emby.Releases/releases/download/${current}/emby-server-deb_${current}_$(_os_arch).deb >> $log 2>&1 || {
    echo_error "Failed to download"
    exit 1
}
echo_progress_done "Installer downloaded"

echo_progress_start "Installing emby package"
dpkg -i /tmp/emby.dpkg >> $log 2>&1 || {
    echo_error "Failed to install package"
    exit 1
}
rm /tmp/emby.dpkg
echo_progress_done "Emby package installed"

if [[ -f /etc/emby-server.conf ]]; then
    printf "\nEMBY_USER="${username}"\nEMBY_GROUP="${username}"\n" >> /etc/emby-server.conf
fi

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Setting up Emby nginx configuration"
    bash /usr/local/bin/swizzin/nginx/emby.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Emby will run on port 8096"
fi

echo_progress_start "Starting Emby"
usermod -a -G ${username} emby
systemctl restart emby-server > /dev/null 2>&1
echo_progress_done
touch /install/.emby.lock
echo_success "Emby installed"

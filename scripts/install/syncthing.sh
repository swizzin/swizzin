#!/bin/bash
#
# [Quick Box :: Install syncthing]
#
# GITHUB REPOS
# GitHub _ packages  :   https://github.com/QuickBox/quickbox_packages
# LOCAL REPOS
# Local _ packages   :   /etc/QuickBox/packages
# Author             :   QuickBox.IO | liara
# URL                :   https://quickbox.io
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

MASTER=$(cut -d: -f1 < /root/.master.info)

echo_progress_start "Adding Syncthing Repository"
curl -s https://syncthing.net/release-key.txt | gpg --dearmor > /usr/share/keyrings/syncthing-archive-keyring.gpg 2>> "${log}"
echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] http://apt.syncthing.net/ syncthing release" > /etc/apt/sources.list.d/syncthing.list
echo_progress_done "Repo added"
apt_update

apt_install syncthing

echo_progress_start "Configuring Syncthing & Starting"
cat > /etc/systemd/system/syncthing@.service << SYNC
[Unit]
Description=Syncthing - Open Source Continuous File Synchronization for %i
Documentation=man:syncthing(1)
After=network.target
Wants=syncthing-inotify@.service

[Service]
User=%i
ExecStart=/usr/bin/syncthing -no-browser -no-restart -logflags=0
Restart=on-failure
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

[Install]
WantedBy=multi-user.target
SYNC
systemctl enable -q syncthing@${MASTER} 2>&1 | tee -a $log
systemctl start syncthing@${MASTER} >> $log 2>&1
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/syncthing.sh
    systemctl reload nginx
    echo_progress_done
else
    echo_info "Syncthing will run on port 8384"
fi

touch /install/.syncthing.lock
echo_success "Syncthing installed"

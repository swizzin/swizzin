#!/bin/bash
#
# [Quick Box :: Install Resilio Sync (BTSync) package]
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
MASTER=$(cut -d: -f1 < /root/.master.info)
BTSYNCIP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

function _installBTSync1() {
    echo "deb [signed-by=/usr/share/keyrings/btsync-archive-keyring.gpg] http://linux-packages.resilio.com/resilio-sync/deb resilio-sync non-free" > /etc/apt/sources.list.d/btsync.list
    curl -s https://linux-packages.resilio.com/resilio-sync/key.asc | gpg --dearmor > /usr/share/keyrings/btsync-archive-keyring.gpg 2>> "${log}"
    apt_update
}

function _installBTSync3() {
    cd && mkdir -p /home/"${MASTER}"/.config/resilio-sync/storage/
    apt_install resilio-sync
}
function _installBTSync4() {
    cd && mkdir /home/"${MASTER}"/sync_folder
    chown ${MASTER}: /home/${MASTER}/sync_folder
    chmod 2775 /home/${MASTER}/sync_folder
    chown ${MASTER}: -R /home/${MASTER}/.config/
}
function _installBTSync5() {
    cat > /etc/resilio-sync/config.json << RSCONF
{
    "listening_port" : 0,
    "storage_path" : "/home/${MASTER}/.config/resilio-sync/",
    "pid_file" : "/var/run/resilio-sync/sync.pid",

    "webui" :
    {
        "listen" : "${BTSYNCIP}:8888"
    }
}
RSCONF
    cp -a /lib/systemd/system/resilio-sync.service /etc/systemd/system/
    sed -i "s/=rslsync/=${MASTER}/g" /etc/systemd/system/resilio-sync.service
    sed -i "s/rslsync:rslsync/${MASTER}:${MASTER}/g" /etc/systemd/system/resilio-sync.service
    systemctl daemon-reload
}
function _installBTSync6() {
    touch /install/.btsync.lock
    systemctl enable -q resilio-sync 2>&1 | tee -a $log
    systemctl start resilio-sync >> $log 2>&1
    systemctl restart resilio-sync >> $log 2>&1
}

echo_progress_start "Installing btsync keys and sources"
_installBTSync1
echo_progress_done "Keys and sources added"

echo_progress_start "Installing btsync"
_installBTSync3
echo_progress_done "Installed"

echo_progress_start "Setting up btsync permissions"
_installBTSync4
echo_progress_done

echo_progress_start "Setting up btsync configurations"
_installBTSync5
echo_progress_done "Configured"

echo_progress_start "Starting btsync"
_installBTSync6
echo_progress_done "Started"

echo_success "BTSync installed"

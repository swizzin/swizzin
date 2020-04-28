#!/bin/bash
# Author: Flying_sausages 2020 for Swizzin

############################################################
# Functions
############################################################

_mkservice_transmission() {
    echo "Creating systemd services"
    cat > /etc/systemd/system/transmission@.service <<EOF
[Unit]
Description=Transmission BitTorrent Daemon
After=network.target

[Service]
User=%i
Group=%i
Type=simple
ExecStart=/usr/bin/transmission-daemon -f --log-error
ExecReload=/bin/kill -s HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
}

_start_transmission () {
    #This always needs to be done only after the configs have been made, otherwise transmission will overwrite them.
    systemctl enable transmission@${user} 2>> $log
    service transmission@${user} start
}



_setenv_transmission(){
    [[ -z $download_dir ]] && export download_dir='transmission/downloads'
    [[ -z $incomplete_dir ]] && export incomplete_dir='transmission/incomplete'
    [[ -z $incomplete_dir_enabled ]] && export incomplete_dir_enabled="false"
    [[ -z $rpc_whitelist ]] && export rpc_whitelist='*.*.*.*'
    [[ -z $rpc_whitelist_enabled ]] && export rpc_whitelist_enabled='0'
    . /etc/swizzin/sources/functions/transmission
    [[ -z $rpc_port ]] && export rpc_port=$(_get_next_port_from_json 'rpc-port' 9091)
    [[ -z $peer_port ]] && export peer_port=$(_get_next_port_from_json 'peer-port' 51314)
    . /etc/swizzin/sources/functions/utils
    [[ -z $rpc_password ]] && export rpc_password=$(_get_user_password ${user})
}

_mkdir_transmission (){
    mkdir -p /home/${user}/${download_dir}
    chown ${user}:${user} -R /home/${user}/${download_dir}
    mkdir -p /home/${user}/.config/transmission-daemon
    mkdir -p /home/${user}/.config/transmission-daemon/blocklists
    mkdir -p /home/${user}/.config/transmission-daemon/resume
    mkdir -p /home/${user}/.config/transmission-daemon/torrents
    chown ${user}:${user} -R /home/${user}/.config

    if [[ $incomplete_dir_enabled = "true" ]]; then 
        mkdir -p /home/${user}/${incomplete_dir}
        chown ${user}:${user} -R /home/${user}/${incomplete_dir}
    fi
}

_mkconf_transmission () {
    _setenv_transmission 
cat > /home/${user}/.config/transmission-daemon/settings.json <<EOF
{
    "alt-speed-down": 50,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-day": 127,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-up": 50,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "blocklist-url": "http://www.example.com/blocklist",
    "cache-size-mb": 4,
    "dht-enabled": false,
    "download-dir": "/home/${user}/transmission/downloads",
    "download-limit": 100,
    "download-limit-enabled": 0,
    "download-queue-enabled": true,
    "download-queue-size": 5,
    "encryption": 1,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": "/home/${user}/${incomplete_dir}",
    "incomplete-dir-enabled": ${incomplete_dir_enabled},
    "lpd-enabled": false,
    "max-peers-global": 200,
    "message-level": 1,
    "peer-congestion-algorithm": "",
    "peer-id-ttl-hours": 6,
    "peer-limit-global": 200,
    "peer-limit-per-torrent": 50,
    "peer-port": ${peer_port},
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": false,
    "peer-socket-tos": "default",
    "pex-enabled": true,
    "port-forwarding-enabled": false,
    "preallocation": 1,
    "prefetch-enabled": true,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit": 2,
    "ratio-limit-enabled": false,
    "rename-partial-files": true,
    "rpc-authentication-required": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-enabled": true,
    "rpc-host-whitelist": "",
    "rpc-host-whitelist-enabled": true,
    "rpc-password": "${rpc_password}",
    "rpc-port": ${rpc_port},
    "rpc-url": "/transmission/",
    "rpc-username": "${user}",
    "rpc-whitelist": "${rpc_whitelist}",
    "rpc-whitelist-enabled": ${rpc_whitelist_enabled},
    "scrape-paused-torrents-enabled": true,
    "script-torrent-done-enabled": false,
    "script-torrent-done-filename": "",
    "seed-queue-enabled": false,
    "seed-queue-size": 10,
    "speed-limit-down": 100,
    "speed-limit-down-enabled": false,
    "speed-limit-up": 100,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "trash-original-torrent-files": false,
    "umask": 18,
    "upload-limit": 100,
    "upload-limit-enabled": 0,
    "upload-slots-per-torrent": 14,
    "utp-enabled": true
}
EOF
echo "Transmission RPC port for ${user} = ${rpc_port}"
# echo "Use the RPC port above and your user credentials to log into Transmission Remote"
# echo "   More info: https://github.com/transmission-remote-gui/transgui"
}

##########################################################################
# Script Main
##########################################################################

export DEBIAN_FRONTEND=noninteractive

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

noexec=$(grep "/tmp" /etc/fstab | grep noexec)
user=$(cut -d: -f1 < /root/.master.info)

# Extra-user-only functions
if [[ -n $1 ]]; then
	user=$1
	_mkdir_transmission
    _mkconf_transmission
	exit 0
fi

#Not sure what this does but I'll copy it for now
if [[ -n $noexec ]]; then
	mount -o remount,exec /tmp
	noexec=1
fi

if [[ -n $noexec ]]; then
	mount -o remount,noexec /tmp
fi

. /etc/swizzin/sources/functions/transmission
_install_transmission
_mkservice_transmission
echo "Creating directories"
_mkdir_transmission
echo "Creating config"
_mkconf_transmission

_start_transmission

touch /install/.transmission.lock

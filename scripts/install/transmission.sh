#!/bin/bash
# shellcheck disable=SC1091
# Author: Flying_sausages 2020 for Swizzin

############################################################
# Functions
############################################################

_mkservice_transmission() {
    echo_progress_start "Creating systemd services"
    cat > /etc/systemd/system/transmission@.service << EOF
[Unit]
Description=Transmission BitTorrent Daemon for %i
After=network.target

[Service]
User=%i
Group=%i
Type=simple
ExecStart=/usr/bin/transmission-daemon -f --log-error --logfile /home/%i/.config/transmission-daemon/transmission.log
ExecReload=/bin/kill -s HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    echo_progress_done "Done"
}

_start_transmission() {
    #This always needs to be done only after the configs have been made, otherwise transmission will overwrite them.
    echo_progress_start "Starting transmission instance for ${bold}$user"
    systemctl enable -q transmission@${user} 2>> $log
    service transmission@${user} start
    echo_progress_done "Instance started"
}

_setenv_transmission() {
    echo_log_only "Setting environment variables"
    [[ -z $download_dir ]] && export download_dir='transmission/downloads'
    echo_log_only "download_dir = $download_dir"

    [[ -z $incomplete_dir ]] && export incomplete_dir='transmission/incomplete'
    echo_log_only "incomplete_dir = $incomplete_dir"

    [[ -z $incomplete_dir_enabled ]] && export incomplete_dir_enabled="false"
    echo_log_only "incomplete_dir_enabled = $incomplete_dir_enabled"

    [[ -z $rpc_whitelist ]] && export rpc_whitelist='*.*.*.*'
    echo_log_only "rpc_whitelist = $rpc_whitelist"

    [[ -z $rpc_whitelist_enabled ]] && export rpc_whitelist_enabled='0'
    echo_log_only "rpc_whitelist_enabled = $rpc_whitelist_enabled"

    . /etc/swizzin/sources/functions/transmission
    [[ -z $rpc_port ]] && export rpc_port=$(_get_next_port_from_json 'rpc-port' 9091)
    echo_log_only "rpc_port = $rpc_port"

    [[ -z $peer_port ]] && export peer_port=$(_get_next_port_from_json 'peer-port' 51314)
    echo_log_only "peer_port = $peer_port"

    . /etc/swizzin/sources/functions/utils
    [[ -z $rpc_password ]] && export rpc_password=$(_get_user_password ${user})

    [[ -z $watch_dir ]] && export watch_dir='transmission/watch'
    [[ -z $watch_dir_enabled ]] && export watch_dir_enabled="true"
}

_unsetenv_transmission() {
    # unset download_dir
    # unset incomplete_dir
    # unset incomplete_dir_enabled
    # unset rpc_whitelist
    # unset rpc_whitelist_enabled
    unset rpc_port
    unset peer_port
    unset rpc_password
    # unset watch_dir
    # unset watch_dir_enabled
}

_mkdir_transmission() {
    echo_progress_start "Creating directories for ${bold}$user"
    mkdir -p /home/${user}/${download_dir}
    chown ${user}:${user} -R /home/${user}/${download_dir%%/*}
    mkdir -p /home/${user}/.config/transmission-daemon
    mkdir -p /home/${user}/.config/transmission-daemon/blocklists
    mkdir -p /home/${user}/.config/transmission-daemon/resume
    mkdir -p /home/${user}/.config/transmission-daemon/torrents
    chown ${user}:${user} -R /home/${user}/.config

    if [[ $incomplete_dir_enabled = "true" ]]; then
        mkdir -p /home/${user}/${incomplete_dir}
        chown ${user}:${user} -R /home/${user}/${incomplete_dir%%/*}
    fi

    if [[ $watch_dir_enabled = "true" ]]; then
        mkdir -p /home/${user}/${watch_dir}
        chown ${user}:${user} -R /home/${user}/${watch_dir%%/*}
    fi

    echo_progress_done "Directories created"
}

_mkconf_transmission() {
    echo_progress_start "Creating config for ${bold}$user"
    cat > /home/${user}/.config/transmission-daemon/settings.json << EOF
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
    "download-dir": "/home/${user}/${download_dir}",
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
    "utp-enabled": true,
    "watch-dir": "/home/${user}/${watch_dir}",
    "watch-dir-enabled": ${watch_dir_enabled}
}
EOF
    echo_progress_done "Config created"
    if [[ ! -f /install/.nginx.lock ]]; then
        echo_info "Transmission RPC port for ${bold}${user} = ${rpc_port}"
    fi
}

_nginx_transmission() {
    echo_progress_start "Creating nginx config"
    if [[ -f /install/.nginx.lock ]]; then
        bash /usr/local/bin/swizzin/nginx/transmission.sh
        systemctl reload nginx
    fi
}

##########################################################################
# Script Main
##########################################################################

export DEBIAN_FRONTEND=noninteractive

noexec=$(grep "/tmp" /etc/fstab | grep noexec)
user=$(cut -d: -f1 < /root/.master.info)
users=($(cut -d: -f1 < /etc/htpasswd))

# Extra-user-only functions
if [[ -n $1 ]]; then
    user=$1
    echo_info "Configuring transmission for ${bold}$user"
    _setenv_transmission
    _mkdir_transmission
    _mkconf_transmission
    _nginx_transmission
    _unsetenv_transmission
    _start_transmission
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
for user in ${users[@]}; do
    echo_progress_start "Setting up transmission for $user"
    _setenv_transmission
    _mkdir_transmission
    _mkconf_transmission
    # _start_transmission
    _unsetenv_transmission
    echo_progress_done "Transmission set up for $user"
done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Creating nginx config"
    _nginx_transmission
    echo_progress_done "Nginx configured"
fi

for user in ${users[@]}; do
    _start_transmission
done

echo_success "Transmission installed"

touch /install/.transmission.lock

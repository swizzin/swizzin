#!/bin/bash
# Author: Flying_sausages 2020 for Swizzin
############################################################
#Functions
############################################################

_mkservice() {
    systemctl disable --now transmission-daemon.service

cat >/etc/systemd/system/transmission@.service<<EOF
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
}

_enable_service () {
    systemctl enable --now transmission@${user} 2>> $log
}

_setenv(){
    . /etc/swizzin/sources/functions/transmission
    [[ -z $download_dir ]] && export download_dir='transmission/downloads'
    [[ -z $incomomplete_dir ]] && export incomomplete_dir='transmission/incomplete'
    [[ -z $incomomplete_dir_enabled ]] && export incomomplete_dir_enabled='false'
    [[ -z $peer_port ]] && export peer_port=$(_get_next_port 'peer-port')
    [[ -z $rpc_port ]] && export rpc_port=$(_get_next_port 'rpc-port')
    echo "Using RPC port $rpc_port"
    [[ -z $rpc_whitelist_enabled ]] && export rpc_whitelist_enabled='false'
}

_mkdir (){
    mkdir -p /home/${user}/${download_dir}
    mkdir -p /home/.config/transmission-daemon
    mkdir -p /home/.config/transmission-daemon/blocklists
    mkdir -p /home/.config/transmission-daemon/resume
    mkdir -p /home/.config/transmission-daemon/torrents
    [[ $incomomplete_dir_enabled = "true" ]] &&  mkdir -p /home/${user}/${incomomplete_dir}
}

_mkconf () {

    export $user
    export $rpc_password='nothing_yet' #Retrieve from /root/, can be plaintext. Cannot contain anything that will fuck the json.

    _setenv 
    # "rpc-password": "*(Hh09ajdf-9djfd89ash7a8ggG&*g98h8009hj90": the password for the web interface, replace the hash with a plain text password and it will be hashed on reload 
cat >/home/${user}/.config/transmission-daemon/settings.json<<EOF
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
    "rpc-password": "{6d080fa454e2c1146ef431803785631af64538f9jjARJrkc",
    "rpc-port": $rpc-port,
    "rpc-url": "/transmission/",
    "rpc-username": "${user}",
    "rpc-whitelist": "127.0.0.1",
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

}


##########################################################################

export DEBIAN_FRONTEND=noninteractive

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

noexec=$(grep "/tmp" /etc/fstab | grep noexec)
user=$(cut -d: -f1 < /root/.master.info)
# rutorrent="/srv/rutorrent/"
# port=$((RANDOM%64025+1024))
# portend=$((${port} + 1500))

# Extra-user-only functions
if [[ -n $1 ]]; then
	user=$1
	_makedirs
    _mkconf
	exit 0
fi



#Not sure what this does but I'll copy it for now
if [[ -n $noexec ]]; then
	mount -o remount,exec /tmp
	noexec=1
fi
	  
. /etc/swizzin/sources/functions/transmission

_getversion

if [[ -n $noexec ]]; then
	mount -o remount,noexec /tmp
fi

echo "Installing Transmission";
_install
_mkdir
_mkconf
_systemd


# echo "Installing rTorrent Dependencies ... ";depends_rtorrent
# if [[ ! $rtorrentver == repo ]]; then
#     echo "Building xmlrpc-c from source ... ";build_xmlrpc-c
#     echo "Building libtorrent from source ... ";build_libtorrent_rakshasa
#     echo "Building rtorrent from source ... ";build_rtorrent
# else
#     echo "Installing rtorrent with apt-get ... ";rtorrent_apt
# fi
# echo "Making ${user} directory structure ... ";_makedirs
# echo "setting up rtorrent.rc ... ";_rconf;_systemd




touch /install/.transmission.lock

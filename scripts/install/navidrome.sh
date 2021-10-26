#!/bin/bash
# navidrome installer
# byte 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/navidrome
. /etc/swizzin/sources/functions/navidrome

user=$(_get_master_username)

_systemd() {
    type=simple
    if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
        type=exec
    fi

    echo_progress_start "Installing Systemd service"
    cat > /etc/systemd/system/navidrome.service <<- SERV
[Unit]
Description=Navidrome Music Server and Streamer compatible with Subsonic/Airsonic
After=remote-fs.target network.target
AssertPathExists=/var/lib/navidrome

[Install]
WantedBy=multi-user.target

[Service]
User=${user}
Group=${user}
Type=simple
ExecStart=/opt/navidrome/navidrome --configfile "/var/lib/navidrome/navidrome.toml"
WorkingDirectory=/var/lib/navidrome
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# See https://www.freedesktop.org/software/systemd/man/systemd.exec.html
DevicePolicy=closed
NoNewPrivileges=yes
PrivateTmp=yes
PrivateUsers=yes
ProtectControlGroups=yes
ProtectKernelModules=yes
ProtectKernelTunables=yes
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
RestrictNamespaces=yes
RestrictRealtime=yes
SystemCallFilter=~@clock @debug @module @mount @obsolete @reboot @setuid @swap
ReadWritePaths=/var/lib/navidrome

# You can uncomment the following line if you're not using the jukebox This
# will prevent navidrome from accessing any real (physical) devices
#PrivateDevices=yes

# You can change the following line to strict instead of full if you don't
# want navidrome to be able to write anything on your filesystem outside of
# /var/lib/navidrome.
ProtectSystem=full

# You can uncomment the following line if you don't have any media in /home/*.
# This will prevent navidrome from ever reading/writing anything there.
#ProtectHome=true

# You can customize some Navidrome config options by setting environment variables here. Ex:
Environment=ND_BASEURL="/navidrome"
SERV
echo_progress_done "Navidrome service installed"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx for navidrome"
        bash /etc/swizzin/scripts/nginx/navidrome.sh
        systemctl reload nginx >> $log 2>&1
        echo_progress_done "Nginx configured for navidrome"
    fi
}

_ffmpegrequired() {
if [[ ! -f /install/.ffmpeg.lock ]]; then
    bash /usr/local/bin/swizzin/install/ffmpeg.sh
fi
}

_navidromedirectories() {
echo_progress_start "Making data directory and owning it to ${user}"
mkdir -p "/opt/navidrome"
chown -R "$user":"$user" /opt/navidrome
mkdir -p "/var/lib/navidrome"
chown -R "$user":"$user" /var/lib/navidrome
mkdir -p "/home/$user/music"
chown -R "$user":"$user" "/home/$user/music"
echo_progress_done "Data Directory created and owned."
}

_navidromeconfig() {
echo_progress_start "Installing configuration file"
cat >/var/lib/navidrome/navidrome.toml <<-SERV
MusicFolder = "/home/$user/music"
ND_BASEURL = "/navidrome"
SERV
echo_progress_done "Configuration installed"
}

_navidromedirectories
navidrome_download_latest
_navidromeconfig
_ffmpegrequired
_systemd
_nginx

systemctl enable -q --now navidrome.service 2>&1 | tee -a $log
touch "/install/.navidrome.lock"
echo_success "navidrome installed"

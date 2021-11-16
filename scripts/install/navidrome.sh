#!/bin/bash
# navidrome installer
# byte 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/navidrome
. /etc/swizzin/sources/functions/navidrome

user="$(_get_master_username)"
http_port="4533" # default port used by navidrome

_systemd() {
    type="simple"
    if [[ $(systemctl --version | awk 'NR==1 {print $2}') -ge 240 ]]; then
        type="exec"
    fi

    echo_progress_start "Installing Systemd service"
    cat > /etc/systemd/system/navidrome.service <<- SERV
		[Unit]
		Description=Navidrome Music Server and Streamer compatible with Subsonic/Airsonic
		After=remote-fs.target network.target
		AssertPathExists=/home/${user}/.config/navidrome/

		[Install]
		WantedBy=multi-user.target

		[Service]
		User=${user}
		Group=${user}
		Type=${type}
		ExecStart=/opt/navidrome/navidrome --configfile "/home/${user}/.config/navidrome/navidrome.toml"
		WorkingDirectory=/home/${user}/.config/navidrome/
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
		ReadWritePaths=/home/${user}/.config/navidrome/

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
	SERV
    echo_progress_done "Navidrome service installed"
} 2>> "${log}"

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx for navidrome"
        bash /etc/swizzin/scripts/nginx/navidrome.sh
        systemctl reload nginx &>> "${log}"
        echo_progress_done "Nginx configured for navidrome"
        echo_info "navidrome is now running on /navidrome"
    else
        echo_info "navidrome is now running on port ${http_port}"
    fi
}

_ffmpegrequired() {
    if [[ ! -f /install/.ffmpeg.lock ]]; then
        bash /usr/local/bin/swizzin/install/ffmpeg.sh
    fi
}

_navidromedirectories() {
    echo_progress_start "Making data directory"
    mkdir -p "/opt/navidrome"
    mkdir -p "/home/${user}/.config/navidrome"
    mkdir -p "/home/$user/music"
    echo_progress_done "Data Directory created."
}

_navidromeconfig() {
    echo_progress_start "Installing configuration file"
    cat > "/home/${user}/.config/navidrome/navidrome.toml" <<- SERV
		MusicFolder = "/home/$user/music"
		Port = "${http_port}"
		Address = "0.0.0.0"
		BaseUrl = ""
	SERV
    echo_progress_done "Configuration installed"
}

_navidromeowner() {
    echo_progress_start "Owning directories to $user"
    chown -R "$user":"$user" /opt/navidrome
    chown -R "$user":"$user" "/home/${user}/.config/navidrome"
    chown -R "$user":"$user" "/home/$user/music"
    echo_progress_done "Directory Owned."
}

_navidromedirectories
_navidrome_download_latest
_navidromeconfig
_ffmpegrequired
_systemd
_nginx
_navidromeowner

systemctl enable -q --now navidrome.service &>> "${log}"
touch "/install/.navidrome.lock"
echo_success "navidrome installed"

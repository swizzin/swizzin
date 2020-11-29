#!/bin/bash
# radarr v3 installer
# Flying sauasges for swizzin 2020

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ -z $radarrv3owner ]]; then
	radarrv3owner=$(_get_master_username)
fi

[[ -z $radarrv02owner ]] && radarrv02owner=$(_get_master_username)

_install_radarrv3() {
	apt_install curl mediainfo sqlite3

	radarrv3confdir="/home/$radarrv3owner/.config/Radarr"
	mkdir -p "$radarrv3confdir"
	chown -R "$radarrv3owner":"$radarrv3owner" "$radarrv3confdir"

	echo_progress_start "Downloading source files"
	if ! wget "https://radarr.servarr.com/v1/update/nightly/updatefile?os=linux&runtime=netcore&arch=x64" -O /tmp/Radarrv3.tar.gz >> $log 2>&1; then
		echo_error "Download failed, exiting"
		exit 1
	fi
	echo_progress_done "Source downloaded"

	echo_progress_start "Extracting archive"
	tar -xvf /tmp/Radarrv3.tar.gz -C /opt >> $log 2>&1
	echo_progress_done "Archive extracted"

	touch /install/.radarrv3.lock

	echo_progress_start "Installing Systemd service"
	cat > /etc/systemd/system/radarr.service << EOF
[Unit]
Description=Radarr Daemon
After=syslog.target network.target

[Service]
# Change the user and group variables here.
User=${radarrv3owner}
Group=${radarrv3owner}

Type=simple

# Change the path to Radarr or mono here if it is in a different location for you.
ExecStart=/opt/Radarr/Radarr -nobrowser
TimeoutStopSec=20
KillMode=process
Restart=on-failure

# These lines optionally isolate (sandbox) Radarr from the rest of the system.
# Make sure to add any paths it might use to the list below (space-separated).
#ReadWritePaths=/opt/Radarr /path/to/movies/folder
#ProtectSystem=strict
#PrivateDevices=true
#ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

	systemctl -q daemon-reload
	systemctl enable --now -q radarr
	sleep 1
	echo_progress_done "Radarr service installed and enabled"

	if [[ -f $radarrv3confdir/update_required ]]; then
		echo_progress_start "Radarr is installing an internal upgrade..."
		# echo "You can track the update by running \`systemctl status Radarr\`0. in another shell."
		# echo "In case of errors, please press CTRL+C and run \`box remove sonarrv3\` in this shell and check in with us in the Discord"
		while [[ -f $radarrv3confdir/update_required ]]; do
			sleep 1
			echo_log_only "Upgrade file is still here"
		done
		echo_progress_done "Upgrade finished"
	fi

	echo_progress_start "Configuring security policy"
	#Ensures that local clients running over HTTPS don't need valid certs
	sleep 5
	systemctl -q stop radarr
	sqlite3 "$radarrv3confdir"/radarr.db "INSERT or REPLACE INTO Config VALUES('6', 'certificatevalidation', 'DisabledForLocalAddresses');"
	systemctl -q start radarr
	echo_progress_done "Policy configured"
}

_nginx_radarrv3() {
	if [[ -f /install/.nginx.lock ]]; then
		echo_progress_start "Installing nginx configuration"
		#TODO what is this sleep here for? See if this can be fixed by doing a check for whatever it needs to
		sleep 10
		bash /usr/local/bin/swizzin/nginx/radarrv3.sh
		systemctl -q reload nginx
		echo_progress_done "Nginx configured"
	fi
}

_install_radarrv3
_nginx_radarrv3

if [[ -f /install/.ombi.lock ]]; then
	echo_info "Please adjust your Ombi setup accordingly"
fi

if [[ -f /install/.tautulli.lock ]]; then
	echo_info "Please adjust your Tautulli setup accordingly"
fi

if [[ -f /install/.bazarr.lock ]]; then
	echo_info "Please adjust your Bazarr setup accordingly"
fi

echo_success "Radarr v3 installed"

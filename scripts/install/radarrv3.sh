#!/bin/bash
# radarr v3 installer
# Flying sauasges for swizzin 2020

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ -z $radarrv3owner ]]; then
	radarrv3owner=$(_get_master_username)
fi

[[ -z $radarrv02owner ]] && radarrv02owner=$(_get_master_username)

#Handles existing v0.2 instances
_radarrv02_flow() {
	v02present=false
	if [[ -f /install/.radarr.lock ]]; then
		v02present=true
	fi

	if [[ -f /etc/systemd/system/radarr.service ]]; then
		v02present=true
	fi

	#Should match a v0.2 as those were on Mono
	if [[ -f /opt/Radarr/Radarr.exe ]]; then
		v02present=true
	fi

	if [[ $v02present == "true" ]]; then
		echo_warn "Radarr v0.2 is detected. Continuing will migrate your current v0.2 installation. This will stop and remove Radarr v0.2 You can read more about the migration at https://swizzin.ltd/applications/Radarrv3#migrating-from-v02. An additional copy of the backup will be made into /root/swizzin/backups/radarrv02.bak"
		if ! ask "Do you want to continue?" N; then
			exit 0
		fi

		if ask "Would you like to trigger a Radarr-side backup?" Y; then
			echo_progress_start "Backing up Radarr v0.2"
			if [[ -f /install/.nginx.lock ]]; then
				address="http://127.0.0.1:7878/radarr/api"
			else
				address="http://127.0.0.1:7878/api"
			fi

			if [[ ! -d /home/"${radarrv02owner}"/.config/Radarr ]]; then
				echo_error "No Radarr config folder found for $radarrv02owner. Exiting"
				exit 1
			fi

			apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"${radarrv02owner}"/.config/Radarr/config.xml)
			echo_log_only "apikey = $apikey"

			#This starts a backup on the current Radarr instance. The logic below waits until the query returns as "completed"
			response=$(curl -sd '{name: "backup"}' -H "Content-Type: application/json" -X POST ${address}/command?apikey="${apikey}" --insecure)
			echo_log_only "$response" >> $log
			id=$(echo "$response" | jq '.id')
			echo_log_only "id=$id" >> $log

			if [[ -z $id ]]; then
				echo_warn "We cannot trigger Radarr to dump a current backup, but the current files and previous weekly backups can still be copied"
				if ! ask "Continue without triggering internal Radarr backup?" N; then
					exit 1
				fi
			else
				echo_log_only "Radarr backup Job ID = $id, waiting to finish"
				status=""
				counter=0
				while [[ $status =~ ^(queued|started|)$ ]]; do
					sleep 0.2
					status=$(curl -s "${address}/command/$id?apikey=${apikey}" --insecure | jq -r '.status')
					((counter += 1))
					if [[ $counter -gt 100 ]]; then
						echo_error "Radarr backup took too long, cancelling installation."
						exit 1
					fi
				done
				if [[ $status = "completed" ]]; then
					echo_progress_done "Backup complete"
				else
					echo_error "Radarr returned unexpected status ($status). Terminating. Please try again."
					exit 1
				fi
			fi
		fi

		if [[ -d /root/swizzin/backups/radarrv02.bak ]]; then
			echo_error "A v0.2 backup is already present, please (re)move it as the backup procedure will overwrite it."
			exit 1
		fi

		mkdir -p /root/swizzin/backups/
		echo_progress_start "Copying files to a backup location"
		cp -R /home/"${radarrv02owner}"/.config/Radarr /root/swizzin/backups/radarrv02.bak
		echo_progress_done "Backups copied"

		if [[ "${radarrv02owner}" != "${radarrv3owner}" ]]; then
			echo_progress_start "Copying config to new owner"
			if [[ -d /home/$radarrv3owner/.config/Radarr ]]; then
				rm -rf /home/"$radarrv3owner"/.config/Radarr
			fi
			mkdir -p /home/"${radarrv3owner}"/.config
			cp -R /home/"${radarrv02owner}"/.config/Radarr /home/"$radarrv3owner"/.config/Radarr
			echo_progress_done "Configs copied"
		else
			echo_log_only "No need to migrate, users are the same"
		fi

		systemctl -q stop radarr

		echo_progress_start "Removing Radarr v0.2"
		# shellcheck source=scripts/remove/radarr.sh
		bash /etc/swizzin/scripts/remove/radarr.sh
		echo_progress_done "Radarr v0.2 removed"
	fi
}

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

_radarrv02_flow
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

#!/bin/bash

if [[ -f /install/.radarr.lock ]]; then

	#Move v3mono installs to v3.net
	if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/radarr.service; then
		echo_log_only "Found radarr service pointing to mono"
		##TODO find a different way to check this seeing as we need to query Radarr API, would ben nicer to do from FS
		#shellcheck source=sources/functions/utils
		. /etc/swizzin/sources/functions/utils

		if [[ -z $radarrOwner ]]; then
			radarrOwner=$(_get_master_username)
		fi
		apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" /home/"${radarrOwner}"/.config/Radarr/config.xml)
		# basicauth=$(echo "${radarrOwner}:$(_get_user_password ${radarrOwner})" | base64)
		if [[ -f /install/.nginx.lock ]]; then
			ret=$(curl -sS -L --insecure --user "${radarrOwner}":"$(_get_user_password "${radarrOwner}")" "http://localhost/radarr/api/v3/system/status?apiKey=${apikey}")
		else
			ret=$(curl -sS -L --insecure "http://localhost:7878/api/v3/system/status?apiKey=${apikey}")
		fi
		echo_log_only "Content of ret =\n ${ret}"

		isnetcore=$(jq '.isNetCore' <<< "$ret")

		if [[ $isnetcore = "false" ]]; then # This case confirms we are running on v3 without .net core, i.e. the case we want to update
			echo_info "Moving Radarr from mono to .Net"

			echo_progress_start "Downloading source files"
			if ! curl "https://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64" -L -o /tmp/Radarr.tar.gz >> "$log" 2>&1; then
				echo_error "Download failed, exiting"
				exit 1
			fi
			echo_progress_done "Source downloaded"

			echo_progress_start "Extracting archive"
			systemctl stop radarr -q
			rm /opt/Radarr/Radarr.exe
			tar -xvf /tmp/Radarr.tar.gz -C /opt >> "$log" 2>&1
			chown -R "$radarrOwner":"$radarrOwner" /opt/Radarr
			echo_progress_done "Archive extracted"

			sed -i "s|ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe|ExecStart=/opt/Radarr/Radarr|g" /etc/systemd/system/radarr.service #Watch out! If this condition runs, the updater will not trigger anymore. keep this at the bottom.
			systemctl daemon-reload
			systemctl start radarr -q
			echo_success "Radarr upgraded to .Net"

			echo_progress_start "Upgrading nginx config for Radarr"
			bash /etc/swizzin/scripts/nginx/radarr.sh
			systemctl reload nginx -q
			echo_progress_done "Nginx conf for Radarr upgraded"

		else #	This case triggers if the v3 API did not return correctly, which would indicate a switched off v3 or a v02
			echo_warn "Please migrate your radarr instance manually to v3 via the application's interface, or ennsure it's running if it's on v3 already.
The next time you will run 'box update', the instance will be migrated to .Net core
Please consult the support in Discord if this message is persistent"
			echo_docs "application/radarr#Migrating-to-v3-on-.Net-Core "
		fi
	fi

	#If nginx config is missing the attributes to have radarrv3 refresh UI right, then trigger the nginx script and reload
	if ! grep "proxy_http_version 1.1" /etc/nginx/apps/radarr.conf -q; then
		echo_progress_start "Upgrading nginx config for Radarr"
		bash /etc/swizzin/scripts/nginx/radarr.sh
		systemctl reload nginx -q
		echo_progress_done "Nginx conf for Radarr upgraded"
	fi

fi

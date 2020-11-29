#!/bin/bash

if [[ -f /install/.radarr.lock ]]; then

	#Update Radarr to .net install if it is running and on on v3
	##TODO find a different way to check this seeing as we need to query Radarr API every update, would ben nicer to do from FS
	#shellcheck source=sources/functions/utils
	. /etc/swizzin/sources/functions/utils
	radarruser=$(_get_master_username) #TODO should this be double-checked against the service and/or overrides in case the user has changed it?
	apikey=$(grep -oPm1 "(?<=<ApiKey>)[^<]+" /home/"${radarruser}"/.config/Radarr/config.xml)
	# basicauth=$(echo "${radarruser}:$(_get_user_password ${radarruser})" | base64)
	if [[ -f /install/.nginx.lock ]]; then
		ret=$(curl -sS -L --insecure --user "${radarruser}":"$(_get_user_password "${radarruser}")" "http://localhost/radarr/api/v3/system/status?apiKey=${apikey}")
	else
		ret=$(curl -sS -L --insecure "http://localhost:7878/api/v3/system/status?apiKey=${apikey}")
	fi
	isnetcore=$(jq '.isNetCore' <<< "$ret")

	if [[ $isnetcore = "false" ]]; then
		echo_info "Moving Radarr from mono to .Net"
		systemctl stop radarr -q
		sed -i "s|ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe|ExecStart=/opt/Radarr/Radarr|g" /etc/systemd/system/radarr.service
		systemctl daemon-reload
		## TODO replace binary

		echo_progress_start "Downloading source files"
		if ! wget "https://radarr.servarr.com/v1/update/nightly/updatefile?os=linux&runtime=netcore&arch=x64" -O /tmp/Radarrv3.tar.gz >> $log 2>&1; then
			echo_error "Download failed, exiting"
			exit 1
		fi
		echo_progress_done "Source downloaded"

		echo_progress_start "Extracting archive"
		tar -xvf /tmp/Radarrv3.tar.gz -C /opt >> $log 2>&1
		chown -R "$radarruser":"$radarruser" /opt/Radarr
		echo_progress_done "Archive extracted"

		systemctl start radarr -q
		echo_success "Radarr upgraded to .Net"
	else
		echo_log_only "Content of ret =\n ${ret}"
	fi

	#If nginx config is missing the attributes to have radarrv3 refresh UI right, then trigger the nginx script and reload
	if ! grep "proxy_http_version 1.1" /etc/nginx/apps/radarr.conf -q; then
		echo_progress_start "Upgrading nginx config for Radarr"
		bash /etc/swizzin/scripts/nginx/radarr.sh
		systemctl reload nginx -q
		echo_progress_done "Nginx conf for Radarr upgraded"
	fi

fi

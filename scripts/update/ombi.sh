#!/bin/bash
if [[ -f /install/.ombi.lock ]]; then
	# Change ombi service to stock one
	if [[ -f /etc/systemd/system/ombi.service ]]; then
		echo_progress_start "Moving ombi back to stock service file"
		systemctl cat ombi >> $log
		if systemctl is-active ombi -q; then
			ombiwasactive=true
			systemctl -q stop ombi
		fi
		rm /etc/systemd/system/ombi.service
		systemctl daemon-reload
		systemctl cat ombi >> $log

		if [[ -f /install/.nginx.lock ]]; then
			bash /etc/swizzin/scripts/nginx/ombi.sh
			systemctl reload nginx
		fi

		if [[ $ombiwasactive = "true" ]]; then
			systemctl start ombi
		fi
		echo_progress_done "Ombi reset back to stock service"
	fi
fi

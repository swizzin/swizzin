#!/bin/bash

if [[ -f /install/organizr.sh ]]; then
	# If there is no mention of the v2 api, re-run nginx config
	if ! grep -q api/v2 /etc/nginx/apps/organizr.conf; then
		#shellcheck source=scripts/nginx/organizr.sh
		echo_progress_start "Updating organizr nginx config to v2.1"
		bash /etc/swizzin/scripts/nginx/organizr.sh
		echo_progress_done "Organizr nginx config updated"
	fi
fi

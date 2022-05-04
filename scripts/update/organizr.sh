#!/bin/bash

if [[ -f /install/organizr.sh ]]; then
    # If there is no mention of the v2 api, re-run nginx config
    if ! grep -q api/v2 /etc/nginx/apps/organizr.conf; then
        #shellcheck source=scripts/nginx/organizr.sh
        echo_progress_start "Updating organizr to v2.1"
        bash /etc/swizzin/scripts/nginx/organizr.sh
        echo_progress_done "Organizr nginx config updated"

        echo_progress_start "Pulling down new organizr source code"
        sudo -u www-data git -C "/srv/organizr" pull >> "${log:?}"
        echo_progress_done "Retrieved new organizr source code"
    fi

fi

#!/bin/bash

if [[ -f /etc/apt/sources.list.d/plexmediaserver.list ]]; then
    if grep -q "/deb/" /etc/apt/sources.list.d/plexmediaserver.list; then
        echo_info "Updating plex apt repo endpoint"
        echo "deb https://downloads.plex.tv/repo/deb public main" > /etc/apt/sources.list.d/plexmediaserver.list
        apt_update
    fi
fi

# removing lockfile for the upgrade script so that it can be re-run as many times as people want
if [ -f "/install/.updateplex.lock" ]; then
    # echo file exists
    rm /install/.updateplex.lock
fi

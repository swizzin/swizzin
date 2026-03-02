#!/bin/bash

if [[ -f /etc/apt/sources.list.d/plexmediaserver.list ]]; then
    echo_info "Updating plex apt repo endpoint"
    rm /etc/apt/sources.list.d/plexmediaserver.list
    rm /usr/share/keyrings/plex-archive-keyring.gpg
    curl -sL https://downloads.plex.tv/plex-keys/PlexSign.v2.key | gpg --yes --dearmor -o /usr/share/keyrings/plexmediaserver.v2.gpg
    echo "deb [signed-by=/usr/share/keyrings/plexmediaserver.v2.gpg] https://repo.plex.tv/deb/ public main" > /etc/apt/sources.list.d/plex.list >> ${log} 2>&1
    apt_update
fi

# removing lockfile for the upgrade script so that it can be re-run as many times as people want
if [ -f "/install/.updateplex.lock" ]; then
    # echo file exists
    rm /install/.updateplex.lock
fi

#!/bin/bash

#Update club-QuickBox with latest changes
if [[ -d /srv/rutorrent/plugins/theme/themes/club-QuickBox ]]; then
    cd /srv/rutorrent/plugins/theme/themes/club-QuickBox
    git reset HEAD --hard
    git pull
fi

if [[ -d /srv/rutorrent/plugins/theme/themes/DarkBetter ]]; then
    if [[ -z "$(ls -A /srv/rutorrent/plugins/theme/themes/DarkBetter/)" ]]; then
        cd /srv/rutorrent
        git submodule update --init --recursive > /dev/null 2>&1
    fi
fi
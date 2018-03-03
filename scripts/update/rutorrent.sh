#!/bin/bash

#Update club-QuickBox with latest changes
if [[ -d /srv/rutorrent/plugins/theme/themes/club-QuickBox ]]; then
    cd /srv/rutorrent/plugins/theme/themes/club-QuickBox
    git reset HEAD --hard
    git pull
fi
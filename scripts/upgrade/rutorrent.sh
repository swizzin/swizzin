#!/bin/bash
# ruTorrent upgrade wrapper
# Author: liara
# Does not update from git remote at this time...

if [[ -d /srv/rutorrent ]] && [[ ! -f /install/.rutorrent.lock ]]; then
	touch /install/.rutorrent.lock
fi

if [[ ! -f /install/.rutorrent.lock ]]; then
	echo_error "ruTorrent doesn't appear to be installed. Script exiting."
	exit 1
fi

bash /usr/local/bin/swizzin/nginx/rutorrent.sh
systemctl reload nginx

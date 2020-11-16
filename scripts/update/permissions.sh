#!/bin/bash

find /home -mindepth 1 -maxdepth 1 -type d -exec chmod 750 {} \;

if [[ -f /install/.plex.lock ]]; then
	master=$(_get_master_username)
	if [[ -z $(groups plex | grep ${master}) ]]; then
		usermod -a -G ${master} plex
	fi
fi

if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.profile; then
	sed -i '/export PATH=$PATH:\/usr\/local\/bin\/swizzin/d' /root/.profile
fi

if grep -q 'export PATH=$PATH:/usr/local/bin/swizzin' /root/.bashrc; then
	:
else
	echo 'export PATH=$PATH:/usr/local/bin/swizzin' >> /root/.bashrc
fi

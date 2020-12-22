#!/bin/bash
. /etc/swizzin/sources/functions/utils
user=$(_get_master_username)
systemctl disable --now nzbhydra

#Old nzbhydra1 installs
rm_if_exists /opt/nzbhydra
rm_if_exists /home/${user}/.config/nzbhydra
rm_if_exists /opt/.venv/nzbhydra
if [ -z "$(ls -A /opt/.venv)" ]; then
    rm -rf /opt/.venv
fi

#nzbhydra2 installs
rm_if_exists /opt/nzbhydra2
rm_if_exists /home/${user}/.config/nzbhydra2

rm /etc/systemd/system/nzbhydra.service
rm -f /etc/nginx/apps/nzbhydra.conf
rm /install/.nzbhydra.lock
systemctl reload nginx

#!/bin/bash
# Remove autodl from swizzin
#
users=($(cut -d: -f1 < /etc/htpasswd))
rm -rf /srv/rutorrent/plugins/autodl-irssi
for u in $(_get_user_list); do
	systemctl disable --now -q irssi@${u}
	rm -rf /home/${u}/.autodl
	rm -rf /home/${u}/.irssi
done
rm /etc/systemd/system/irssi@.service
rm /install/.autodl.lock

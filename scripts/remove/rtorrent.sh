#!/bin/bash
users=($(cut -d: -f1 < /etc/htpasswd))

if [[ -f /install/.rutorrent.lock || -f /install/.flood.lock ]]; then
    if ! ask "This will remove ruTorrent&/Flood. Continue?" Y; then
        exit 0
    fi
fi
for u in ${users}; do
    systemctl disable -q rtorrent@${u}
    systemctl stop -q rtorrent@${u}
    rm -f /home/${u}/.rtorrent.rc
done

#shellcheck source=sources/functions/rtorrent
. /etc/swizzin/sources/functions/rtorrent
isdeb=$(dpkg -l | grep rtorrent)
echo_progress_start "Removing old rTorrent binaries and libraries ... "
if [[ -z $isdeb ]]; then
    remove_rtorrent_legacy
else
    remove_rtorrent
fi
echo_progress_done

for a in rutorrent flood; do
    if [[ -f /install/.$a.lock ]]; then
        /usr/local/bin/swizzin/remove/$a.sh
    fi
done
rm /etc/systemd/system/rtorrent@.service
rm /install/.rtorrent.lock

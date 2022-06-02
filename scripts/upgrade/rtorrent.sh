#!/bin/bash
# rtorrent upgrade/downgrade/reinstall script
# Author: liara

if [[ ! -f /install/.rtorrent.lock ]]; then
    echo_error "rTorrent doesn't appear to be installed. What do you hope to accomplish by running this script?"
    exit 1
fi

_systemd() {
    # If rtorrent service file contains one line with 'ExecStartPre'
    # Insert two new lines into the file to add vmtouch support
    if [[ espcount == 1 ]]; then
        # After the line starting with "ExecStartPre=-/bin/rm", insert on the next line:
        # ExecStartPre=-/usr/local/bin/vmtouch -i '*.torrent' -m 90K -dl /srv/rutorrent/
        sed -i '/^ExecStartPre=\-\/bin\/rm*/a ExecStartPre=\-\/usr\/local\/bin\/vmtouch \-i '\''*.torrent'\'' -m 90K -dl \/srv\/rutorrent\/' /etc/systemd/system/rtorrent@.service
        # After the line starting with "ExecStartPre=-/usr/local/bin/vmtouch", insert on the next line:
        # ExecStartPre=-/usr/local/bin/vmtouch -I '*.torrent.libtorrent_resume' -I '*.torrent.rtorrent' -m 5K -dl /home/%i/.sessions/
        sed -i '/^ExecStartPre=\-\/usr\/local\/bin\/vmtouch*/a ExecStartPre=\-\/usr\/local\/bin\/vmtouch \-I '\''*.torrent.libtorrent_resume'\'' -I '\''*.torrent.rtorrent'\'' -m 5K -dl \/home\/%i\/.sessions\/' /etc/systemd/system/rtorrent@.service
    fi

    # If available memory is greater than 2GB
    if [[ $memory > 2048 ]]; then
        # Increase vmtouch limit for session files from 5K to 125K
        sed -i 's/\-m 5K/\-m 125K/g' /etc/systemd/system/rtorrent@.service
    fi
}

export DEBIAN_FRONTEND=noninteractive

#shellcheck source=sources/functions/rtorrent
. /etc/swizzin/sources/functions/rtorrent
whiptail_rtorrent

user=$(cut -d: -f1 < /root/.master.info)
rutorrent="/srv/rutorrent/"
users=($(cut -d: -f1 < /etc/htpasswd))
memory = $(awk '/MemAvailable/ {printf( "%.f\n", $2 / 1024 )}' /proc/meminfo)
espcount = $(grep -o 'ExecStartPre' /etc/systemd/system/rtorrent@.service | wc -l)

if [[ -n $noexec ]]; then
    mount -o remount,exec /tmp
    noexec=1
fi
isdeb=$(dpkg -l | grep rtorrent)
echo_progress_start "Removing old rTorrent binaries and libraries ... "
if [[ -z $isdeb ]]; then
    remove_rtorrent_legacy
else
    remove_rtorrent
fi
echo_progress_done

echo_progress_start "Checking rTorrent Dependencies ... "
depends_rtorrent
echo_progress_done
echo_progress_start "Building vmtouch from source"
build_vmtouch
echo_progress_done
if [[ ! $rtorrentver == repo ]]; then
    echo_progress_start "Building xmlrpc-c from source ... "
    build_xmlrpc-c
    echo_progress_done
    echo_progress_start "Building libtorrent from source ... "
    build_libtorrent_rakshasa
    echo_progress_done
    echo_progress_start "Building rtorrent from source ... "
    build_rtorrent
    echo_progress_done
else
    echo_progress_start "Installing rtorrent with apt-get ... "
    rtorrent_apt
    echo_progress_done
fi
echo_progress_start "Updating systemd serivce "
_systemd
echo_progress_done

if [[ -n $noexec ]]; then
    mount -o remount,noexec /tmp
fi

for u in "${users[@]}"; do
    if grep -q localhost /home/$u/.rtorrent.rc; then sed -i 's/localhost/127.0.0.1/g' /home/$u/.rtorrent.rc; fi
    systemctl try-restart rtorrent@${u}
done

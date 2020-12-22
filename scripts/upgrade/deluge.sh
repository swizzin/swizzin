#!/bin/bash
# Deluge upgrade/downgrade/reinstall script
# Author: liara
if [[ ! -f /install/.deluge.lock ]]; then
    echo_error "Deluge doesn't appear to be installed. What do you hope to accomplish by running this script?"
    exit 1
fi

. /etc/swizzin/sources/functions/deluge
. /etc/swizzin/sources/functions/libtorrent

whiptail_deluge
check_client_compatibility
whiptail_deluge_downupgrade
dver=$(deluged -v | grep deluged | grep -oP '\d+\.\d+\.\d+')
if [[ $dver == 1.3* ]] && [[ $deluge == master ]]; then
    echo_info "Major version upgrade detected. User-data will be backed-up."
fi
users=($(cut -d: -f1 < /etc/htpasswd))

for u in "${users[@]}"; do
    if [[ $dver == 1.3* ]] && [[ $deluge == master ]]; then
        echo_info "'/home/${u}/.config/deluge' -> '/home/$u/.config/deluge.$$'"
        cp -a /home/${u}/.config/deluge /home/${u}/.config/deluge.$$
    fi
done

echo_progress_start "Checking for outdated deluge install method."
remove_ltcheckinstall

if ! skip_libtorrent_rasterbar; then
    whiptail_libtorrent_rasterbar
    echo_progress_start "Rebuilding libtorrent"
    build_libtorrent_rasterbar
    echo_progress_done
fi
cleanup_deluge
echo_progress_start "Upgrading Deluge. Please wait"
build_deluge
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Reconfiguring deluge nginx configs"
    bash /usr/local/bin/swizzin/nginx/deluge.sh
    systemctl reload nginx
    echo_progress_done
fi

echo_progress_start "Fixing Web Service and Hostlist"
dweb_check
echo_progress_done

for u in "${users[@]}"; do
    echo_progress_start "Running ltconfig check ..."
    ltconfig
    echo_progress_done
    systemctl try-restart deluged@${u}
    systemctl try-restart deluge-web@${u}
done

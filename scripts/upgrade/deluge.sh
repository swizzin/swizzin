#!/bin/bash
# Deluge upgrade/downgrade/reinstall script
# Author: liara
if [[ ! -f /install/.deluge.lock ]]; then
    echo_error "Deluge doesn't appear to be installed. What do you hope to accomplish by running this script?"
    exit 1
fi

#shellcheck source=sources/functions/deluge
. /etc/swizzin/sources/functions/deluge
#shellcheck source=sources/functions/libtorrent
. /etc/swizzin/sources/functions/libtorrent
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
#shellcheck source=sources/functions/fpm
. /etc/swizzin/sources/functions/fpm

whiptail_deluge

case ${DELUGE_VERSION} in
    [Rr][Ee][Pp][Oo])
        check_shared_libtorrent_rasterbar deluge
        apt_install_deluge
        ;;
    *)
        detect_libtorrent_rasterbar_conflict deluge
        whiptail_deluge_downupgrade
        deluge_version_info
        dver=$(deluged -v | grep deluged | grep -oP '\d+\.\d+\.\d+')
        users=($(_get_user_list))
        if [[ $dver == 1.3* ]] && [[ $DELUGE_VERSION == master ]]; then
            echo_info "Major version upgrade detected. User-data will be backed-up."
            for u in "${users[@]}"; do
                echo_info "'/home/${u}/.config/deluge' -> '/home/$u/.config/deluge.$$'"
                cp -a /home/${u}/.config/deluge /home/${u}/.config/deluge.$$

            done
        fi
        echo_progress_start "Checking for outdated deluge install method."
        remove_ltcheckinstall

        install_fpm
        if ! skip_libtorrent_deluge; then
            check_swap_on
            echo_progress_start "Rebuilding libtorrent"
            build_libtorrent_deluge
            check_swap_off
            echo_progress_done
        fi
        cleanup_deluge
        echo_progress_start "Upgrading Deluge. Please wait"
        build_deluge
        cleanup_repo_libtorrent
        echo_progress_done
        ;;
esac

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

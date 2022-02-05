#!/bin/bash
# qBittorrent Installer for swizzin
# Author: liara

if [[ ! -f /install/.qbittorrent.lock ]]; then
    echo_error "qBittorrent doesn't appear to be installed. What do you hope to accomplish by running this script?"
    exit 1
fi

# Source the required functions
. /etc/swizzin/sources/functions/qbittorrent
. /etc/swizzin/sources/functions/libtorrent
. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/fpm

users=($(_get_user_list))
qbtvold=$(qbittorrent-nox --version 2> /dev/null | grep -oP '\d+\.\d+\.\d+' || echo '0.0.0.0')

whiptail_qbittorrent

case ${QBITTORRENT_VERSION} in
    [Rr][Ee][Pp][Oo])
        apt_remove --purge qbittorrent-nox
        check_shared_libtorrent_rasterbar qbittorrent
        apt_install qbittorrent-nox
        ;;
    *)
        detect_libtorrent_rasterbar_conflict qbittorrent
        qbittorrent_version_info
        install_fpm
        if [[ $build_type == "cmake" ]]; then
            install_cmake_swizzin
        fi
        check_swap_on

        if ! skip_libtorrent_qbittorrent; then
            echo_progress_start "Building libtorrent-rasterbar"
            build_libtorrent_qbittorrent
            echo_progress_done
        fi
        install_qt
        echo_progress_start "Building qBittorrent"
        build_qbittorrent
        cleanup_repo_libtorrent
        echo_progress_done
        check_swap_off
        ;;
esac
qbtvnew=$(qbittorrent-nox --version 2> /dev/null | grep -oP '\d+\.\d+\.\d+')

for user in "${users[@]}"; do
    if dpkg --compare-versions ${qbtvold} lt 4.2.0 && dpkg --compare-versions ${qbtvnew} ge 4.2.0; then
        #Reset user password to ensure login continues to work if doing a major upgrade (>4.2 to <4.2)
        #chpasswd function restarts qbittorrent, which we need to anyway. No need for a further restart.
        password=$(_get_user_password ${user})
        qbittorrent_chpasswd "${user}" "${password}"
    elif dpkg --compare-versions ${qbtvold} ge 4.2.0 && dpkg --compare-versions ${qbtvnew} lt 4.2.0; then
        #The inverse of above -- if downgrading from >4.2 to <4.2 change password hash for old version
        password=$(_get_user_password ${user})
        qbittorrent_chpasswd "${user}" "${password}"
    else
        #Just restart qbittorrent if no changes to password are needed
        systemctl try-restart qbittorrent@${user}
    fi
done

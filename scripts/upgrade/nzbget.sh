#!/bin/bash
# shellcheck source=sources/functions/users
. /etc/swizzin/sources/functions/users
# shellcheck source=sources/functions/nzbget
. /etc/swizzin/sources/functions/nzbget

if [[ -f /install/.nzbget.lock ]]; then
    if dpkg --compare-versions "$(/home/$(_get_master_username)/nzbget/nzbget --version | cut -d: -f2 | tr -d ' ')" le 21.1; then
        echo_progress_start "Upgrading nzbget to latest."

        users=$(_get_user_list)
        noexec=$(grep "/tmp" /etc/fstab | grep noexec)
        if [[ -n $noexec ]]; then
            mount -o remount,exec /tmp
            noexec=1
        fi

        cd /tmp || {
            echo_error "Failed to change directory to /tmp"
            exit 1
        }

        _download

        for u in "${users[@]}"; do
            echo_progress_start "Upgrading nzbget for $u"
            sh nzbget-latest-bin-linux.run --destdir /home/$u/nzbget >> $log 2>&1
            chown -R $u:$u /home/$u/nzbget
            systemctl try-restart nzbget@${u} >> $log 2>&1
            echo_progress_done "Nzbget upgraded for $u"
        done

        echo_progress_start "Cleaning up"
        rm_if_exists /tmp/nzbget-latest-bin-linux.run

        if [[ -n $noexec ]]; then
            mount -o remount,noexec /tmp
        fi

        echo_progress_done
    fi
fi

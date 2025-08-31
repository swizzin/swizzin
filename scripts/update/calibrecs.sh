#!/bin/bash
if [[ -f /install/.calibrecs.lock ]]; then

    if [[ $(grep -c "users_managed" /install/.calibrecs.lock) -eq 0 ]]; then
        echo_info "Enabling multi-user support for CalibreCS"

        if [ -z "$CALIBRE_LIBRARY_USER" ]; then
            if ! CALIBRE_LIBRARY_USER="$(swizdb get calibre/library_user)"; then
                CALIBRE_LIBRARY_USER=$(_get_master_username)
            fi
        fi
        fix=0
        echo_info "CalibreCS now supports authentication and user accounts. You can either have this done manually, or you can do this manually on your own."
        if ask "Update users for CallibreCS automatically?" Y; then
            echo_progress_start "Migrating users to calibre server"

            readarray -t users < <(_get_user_list)
            for user in "${users[@]}"; do
                echo_log_only "Adding user $user"
                pass=$(_get_user_password "$user")
                # shellcheck source=sources/functions/calibrecs
                source /etc/swizzin/sources/functions/calibrecs
                calibrecs_usrmgr add "$user" "$pass" || {
                    echo_error "Adding $user to calibre server failed."
                    exit 1
                }
            done
            echo_progress_done
            echo "users_managed" >> /install/.calibrecs.lock
            fix=1
        elif ask "Do you acknowledge you need to manually update users for CallibreCS? If yes, this prompt will be skipped." Y; then
            echo "users_managed" >> /install/.calibrecs.lock
            fix=1
        fi

        if [ "$fix" -eq 1 ]; then
            if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
                if ! CALIBRE_LIBRARY_PATH="$(swizdb get calibre/library_path)"; then
                    CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
                fi
            fi
            echo_progress_start "Updating calibrecs systemd"
            append=" --enable-auth --auth-mode=basic --userdb='/home/${CALIBRE_LIBRARY_USER}/.config/calibre/server-users.sqlite'"
            sed "s:^ExecStart.*:& ${append}:" /etc/systemd/system/calibrecs.service

            echo_progress_done
        fi
    fi

fi

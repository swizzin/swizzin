#!/usr/bin/env bash

if [[ ! -f /install/.calibre.lock ]]; then
    echo_error "Calibre Content server requires calibre. Please run \`box install calibre\` first."
    exit 1
fi

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [ -z "$CALIBRE_LIBRARY_USER" ]; then
    CALIBRE_LIBRARY_USER=$(_get_master_username)
fi

if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
    CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
fi

clbServerPath=/home/"$CALIBRE_LIBRARY_USER"/.config/calibre-cs

_adduser() {
    ## TODO handle programatically
    # echo -e "1\n$CALIBRE_LIBRARY_USER\n$pass\n$pass" > /tmp/csuservdinput.txt
    # calibre-server --userdb "$clbServerPath"/server-users.sqlite --manage-users < /tmp/csuservdinput.txt
    # echo_info "You will now be asked to create a user for the calibre content server."
    # echo_query "Press enter to continue" "enter"
    # read
    # calibre-server --userdb "$clbServerPath"/server-users.sqlite --manage-users | tee -a "$log" || {
    #     rm "$clbServerPath"/server-users.sqlite
    #     echo_error "Failed to set up user for calibre-server"
    #     exit 1
    # }

    echo_log_only "Adding user $user"
    user=$1
    pass=$(_get_user_password "$user")
    echo -e "1\n$user\n$pass\n$pass" | calibre-server --userdb "$clbServerPath"/server-users.sqlite --manage-users
}

_install() {
    mkdir -p "$clbServerPath"/
    chown "$CALIBRE_LIBRARY_USER": /home/"$CALIBRE_LIBRARY_USER"/.config # Just in case this is the first time .config is created
    touch "$clbServerPath"/.calibre.log

    # readarray -t users < <(_get_user_list)
    users=("$(_get_master_user)")

    echo_progress_start "Adding users to calibre content server"
    for user in "${users[@]}"; do
        _adduser "$user"
    done

    chown -R "$CALIBRE_LIBRARY_USER": "$clbServerPath"
    echo_progress_done "Users added to calibre content server"
}

_systemd() {
    cat > /etc/systemd/system/calibre-cs.service << CALICS
[Unit]
Description=calibre content server
After=network.target

[Service]
Type=simple
User=$CALIBRE_LIBRARY_USER
Group=$CALIBRE_LIBRARY_USER
ExecStart=/usr/bin/calibre-server --max-opds-items=30 --max-opds-ungrouped-items=100 --port 8089 "${CALIBRE_LIBRARY_PATH:=CALIBRE_LIBRARY_PATH_GOES_HERE}"


[Install]
WantedBy=multi-user.target
    
CALICS
    # ExecStart=/usr/bin/calibre-server --max-opds-items=30 --max-opds-ungrouped-items=100 --port 8089 --log="/home/$CALIBRE_LIBRARY_USER/.config/calibre-cs/.calibre.log" --enable-auth --userdb="/home/$CALIBRE_LIBRARY_USER/.config/calibre/server-users.sqlite" "${CALIBRE_LIBRARY_PATH:=CALIBRE_LIBRARY_PATH_GOES_HERE}"
    echo_progress_done "Calibre content server installed"
    echo_info "The Calibre content server will run on port 8089, please make note of this in case you want to use it in automation"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/calibre-cs.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    fi

    if [[ "$CALIBRE_LIBRARY_SKIP" = "true" ]]; then
        echo_info "Please modify /etc/systemd/system/calibre-cs.service to point to your library accordingly later."
        return
    fi

}

#Handling adding new users post-install
if [[ -n $1 ]]; then
    _adduser "$1"
    exit 0
fi

_install # Removed as we're going to just un-auth the thing and use nginx-based auth instead
_systemd
_nginx

echo_progress_start "Enabling Calibre Content Server"
systemctl enable --now -q calibre-cs
echo_progress_done "Calibre CS enabled"

echo_success "Calibre content server installed"

touch /install/.calibre-cs.lock

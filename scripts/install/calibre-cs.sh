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

_install() {

    mkdir -p /home/"$CALIBRE_LIBRARY_USER"/.config/calibre-cs/
    chown "$CALIBRE_LIBRARY_USER": /home/"$CALIBRE_LIBRARY_USER"/.config # Just in case this is the first time .config is created

    touch /home/"$CALIBRE_LIBRARY_USER"/.config/calibre-cs/.calibre.log
    pass=$(_get_user_password "$CALIBRE_LIBRARY_USER")

    echo_info "You will now be asked to create a user for the calibre content server."
    echo_query "Press enter to continue" "enter"
    read
    ## TODO handle programatically
    # echo -e "1\n$CALIBRE_LIBRARY_USER\n$pass\n$pass" > /tmp/csuservdinput.txt
    # calibre-server --userdb /home/"$CALIBRE_LIBRARY_USER"/.config/calibre-cs/server-users.sqlite --manage-users < /tmp/csuservdinput.txt
    calibre-server --userdb /home/"$CALIBRE_LIBRARY_USER"/.config/calibre-cs/server-users.sqlite --manage-users | tee -a "$log" || {
        rm /home/"$CALIBRE_LIBRARY_USER"/.config/calibre-cs/server-users.sqlite
        echo_error "Failed to set up user for calibre-server"
        exit 1
    }

    chown -R "$CALIBRE_LIBRARY_USER": /home/"$CALIBRE_LIBRARY_USER"/.config/calibre-cs
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
ExecStart=/usr/bin/calibre-server --max-opds-items=30 --max-opds-ungrouped-items=100 --port 8089 --log="/home/$CALIBRE_LIBRARY_USER/.config/calibre/.calibre.log" --enable-auth --userdb="/home/$CALIBRE_LIBRARY_USER/.config/calibre/server-users.sqlite" "${CALIBRE_LIBRARY_PATH:=CALIBRE_LIBRARY_PATH_GOES_HERE}"

[Install]
WantedBy=multi-user.target
    
CALICS
    echo_progress_done "Calibre content server installed"
    echo_info "The Calibre content server will run on port 8089, please make not of this in case you want to use it in automation"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/calibre.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    fi

    if [[ "$CALIBRE_LIBRARY_SKIP" = "true" ]]; then
        echo_info "Please modify /etc/systemd/system/calibre-cs.service to point to your library accordingly later."
        return
    fi

}

_install
_systemd
_nginx

echo_progress_start "Enabling Calibre Content Server"
systemctl enable --now -q calibre-cs
echo_progress_done "Calibre CS enabled"

touch /install/.calibre-cs.lock

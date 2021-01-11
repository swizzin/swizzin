#!/bin/bash
# Calibre installer

_install() {

    apt_install xdg-utils wget xz-utils libxcb-xinerama0 libfontconfig libgl1-mesa-glx

    # TODO make a whiptail to let user install from repo, binaries, or source, and modify that selection based on the arch

    echo_progress_start "Installing calibre"
    if [[ $(_os_arch) = "amd64" ]]; then
        wget https://download.calibre-ebook.com/linux-installer.sh -O /tmp/calibre-installer.sh >> $log 2>&1
        if ! bash /tmp/calibre-installer.sh install_dir=/opt >> $log 2>&1; then
            echo_error "failed to install calibre"
            exit 1
        fi
    else
        echo_info "Calibre needs to be built from source for $(_os_arch)\nWe are falling back onto apt for the time being"
        apt_install calibre
        # : #TODO build calibre from source
    fi
    echo_progress_done "Calibre installed"
}

if [ -n "$CALIBRE_LIBRARY_USER" ]; then
    CALIBRE_LIBRARY_USER=$(_get_master_username)
fi

if [ -n "$CALIBRE_LIBRARY_PATH" ]; then
    CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
fi

_library() {
    if [ -e "$CALIBRE_LIBRARY_PATH" ]; then
        echo_info "Calibre library already exists"
        return
    fi

    if [ "$CALIBRE_LIBRARY_SKIP" = "true" ]; then
        echo_info "Library creation skipped."
        return
    fi

    echo_progress_start "Creating library"

    # Need to start a library with a book so might as well get some good ass literature here
    wget https://www.gutenberg.org/ebooks/59112.epub.images -O /tmp/rur.epub >> $log 2>&1
    wget https://www.gutenberg.org/ebooks/7849.epub.noimages -O /tmp/trial.epub >> $log 2>&1
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils

    mkdir -p "$CALIBRE_LIBRARY_PATH"
    calibredb add /tmp/rur.epub /tmp/trial.epub --with-library "$CALIBRE_LIBRARY_PATH"/ >> $log
    chown -R "$CALIBRE_LIBRARY_USER":"$CALIBRE_LIBRARY_USER" "$CALIBRE_LIBRARY_PATH"/ -R
    chmod 0770 -R "$CALIBRE_LIBRARY_PATH"/
    echo_progress_done "Library installed to $CALIBRE_LIBRARY_PATH"
}

_content_server() {
    echo_progress_start "Installing Calibre Content service"

    mkdir -p /home/"$CALIBRE_LIBRARY_USER"/.config/calibre/
    touch /home/"$CALIBRE_LIBRARY_USER"/.config/calibre/.calibre.log
    pass=$(_get_user_password "$CALIBRE_LIBRARY_USER")

    # TODO see what this does lmao
    echo -e "1\n$CALIBRE_LIBRARY_USER\n$pass\n$pass" > /tmp/csuservdinput.txt
    echo_info "You will now be asked to create a user for the calibre content server."
    read
    ## TODO handle
    # calibre-server --userdb /home/$CALIBRE_LIBRARY_USER/.config/calibre/server-users.sqlite --manage-users
    calibre-server --userdb /home/"$CALIBRE_LIBRARY_USER"/.config/calibre/server-users.sqlite --manage-users < /tmp/csuservdinput.txt

    chown -R "$CALIBRE_LIBRARY_USER": /home/"$CALIBRE_LIBRARY_USER"/.config

    cat > /etc/systemd/system/calibre-cs.service << CALICS
[Unit]
Description=calibre content server
After=network.target

[Service]
Type=simple
User=$CALIBRE_LIBRARY_USER
Group=$CALIBRE_LIBRARY_USER

ExecStart=/usr/bin/calibre-server --max-opds-items=30 --max-opds-ungrouped-items=100 --port 8089 --log="/home/$CALIBRE_LIBRARY_USER/.config/calibre/.calibre.log" --enable-auth --userdb="/home/$CALIBRE_LIBRARY_USER/.config/calibre/server-users.sqlite" ${CALIBRE_LIBRARY_PATH:=CALIBRE_LIBRARY_PATH_GOES_HERE}"
[Install]
WantedBy=multi-user.target
    
CALICS
    echo_progress_done "Calibre content server installed"
    if [[ "$CALIBRE_LIBRARY_SKIP" = "true" ]]; then
        echo_info "Please modify /etc/systemd/system/calibre-cs.service to point to your library accordingly later."
        return
    fi

    if [[ -z $CALIBRE_ENABLE_SERVER ]]; then
        if ask "Would you like to enable and start the Calibre Content Server?"; then
            CALIBRE_ENABLE_SERVER="true"
        fi
    fi

    if [[ $CALIBRE_ENABLE_SERVER = "true" ]]; then
        echo_progress_start "Enablging Calibre Content Server"
        systemctl enable --now -q calibre-cs
        echo_progress_done "Enablging Calibre Content Server"
    else
        echo_info "You can enable the content server later by running 'systemctl enable --now calibre-cs' "
        echo_docs "applications/calibre"
    fi
}

_install
_library
_content_server

touch /install/.calibre.lock
echo_success "Calibre installed"

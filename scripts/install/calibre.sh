#!/bin/bash
# Calibre installer

_install() {

    apt_install xdg-utils wget xz-utils libxcb-xinerama0 libfontconfig libgl1-mesa-glx

    # TODO make a whiptail to let user install from repo, binaries, or source, and modify that selection based on the arch

    echo_progress_start "Installing calibre"
    if [[ $(_os_arch) = "x86_64" ]]; then
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

_library() {
    echo_progress_start "Creating library"

    wget https://www.gutenberg.org/ebooks/59112.epub.images -O /tmp/rur.epub >> $log 2>&1
    wget https://www.gutenberg.org/ebooks/7849.epub.noimages -O /tmp/trial.epub >> $log 2>&1

    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    clbDbUser=$(_get_master_username)
    mkdir /home/"$clbDbUser"/calibre-library
    calibredb add /tmp/*.epub --with-library /home/"$clbDbUser"/calibre-library/ >> $log
    chown -R "$clbDbUser":"$clbDbUser" /home/"$clbDbUser"/calibre-library/ -R
    chmod 0770 -R /home/"$clbDbUser"/calibre-library/
    echo_progress_done
    echo_info "Library installed to /home/$clbDbUser/calibre-library/"
}

_content_server() {
    echo_progress_start "Installing Calibre Content service"

    mkdir -p /home/$clbDbUser/.config/calibre/
    touch /home/$clbDbUser/.config/calibre/.calibre.log
    pass=$(_get_user_password $master)

    # TODO see what this does lmao
    echo -e "1\n$master\n$pass\n$pass" > /tmp/csuservdinput.txt
    calibre-server --userdb /home/$clbDbUser/.config/calibre/server-users.sqlite --manage-users < /tmp/csuservdinput.txt

    chown $clbDbUser: /home/$clbDbUser/.config
    chown -R $clbDbUser: /home/$clbDbUser/.config/calibre

    cat > /etc/systemd/system/calibre-cs.service << CALICS
[Unit]
Description=calibre content server
After=network.target

[Service]
Type=simple
User=$clbDbUser
Group=$clbDbUser

ExecStart=/usr/bin/calibre-server --max-opds-items=30 --max-opds-ungrouped-items=100 --port 8089 --log="/home/$clbDbUser/.config/calibre/.calibre.log" --enable-auth --userdb="/home/$clbDbUser/.config/calibre/server-users.sqlite" "/home/$clbDbUser/calibre-library/"
[Install]
WantedBy=multi-user.target

CALICS

    if [[ -z $CALIBRE_INSTALL_CSERV ]]; then
        if ask "Would you like to enable the Calibre Content Server?"; then
            CALIBRE_INSTALL_CSERV="true"
        fi
    fi
    if [[ $CALIBRE_INSTALL_CSERV = "true" ]]; then
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

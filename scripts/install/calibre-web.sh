#!/bin/bash
# Flying Sausages 2020 for swizzin
#Calibre-web installer

calibrewebdir="/opt/calibre-web"
clbWebUser="calibreweb" # or make this master user?

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [[ -z $CALIBRE_LIBRARY_USER ]]; then
    CALIBRE_LIBRARY_USER="$(_get_master_username)"
fi

if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
    # If not specifically declared, try the default calibre lib in swizzin
    if [ -e "/home/$CALIBRE_LIBRARY_USER/Calibre Library" ]; then
        CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
    fi
fi

if [[ ! -f /install/.calibre.lock ]]; then
    echo_warn "Calibre not found (or installed without swizzin). Having a calibre is functionally required to use calibre-web, but the installer will not fail. You can create a calibre library at a later stage."
    if ask "Install Calibre through swizzin now?" Y; then
        bash /etc/swizzin/scripts/install/calibre.sh || {
            echo_info "Installer failed, please try again"
            exit 1
        }
    fi
fi

function _install_dependencies_calibreweb() {
    apt_install unzip imagemagick
}

function _install_calibreweb() {
    echo_progress_start "Creating venv for calibre-web"
    apt_install python3-pip python3-dev python3-venv
    mkdir -p /opt/.venv/calibre-web
    python3 -m venv /opt/.venv/calibre-web
    echo_progress_done "Venv created"

    echo_progress_start "Downloading Calibre-web source code archive"
    dlurl=$(curl -s https://api.github.com/repos/janeczku/calibre-web/releases/latest | jq -r '.zipball_url')
    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then
        echo_error "Failed to query github"
        exit 1
    fi

    if ! wget -q "${dlurl}" -O /tmp/calibreweb.zip >> $log 2>&1; then
        echo_error "Failed to download source code"
        exit 1
    fi
    echo_progress_done

    echo_progress_start "Extracting archive"
    unzip /tmp/calibreweb.zip -d /tmp/calibrewebdir >> $log 2>&1
    subdir=$(ls /tmp/calibrewebdir)
    mv /tmp/calibrewebdir/"$subdir" $calibrewebdir
    echo_progress_done

    echo_progress_start "Creating users and setting permissions"
    useradd $clbWebUser --system -d "$calibrewebdir" >> $log 2>&1
    chown -R $clbWebUser:$clbWebUser $calibrewebdir
    chown -R ${clbWebUser}: /opt/.venv/calibre-web
    #This bit right here will ensure that the system user created will have access to the master user's folders where he might have the CalibreDB
    usermod -a -G "${CALIBRE_LIBRARY_USER}" $clbWebUser >> $log 2>&1
    echo_progress_done

    echo_progress_start "Installing python dependencies"
    sudo -u ${clbWebUser} bash -c "/opt/.venv/calibre-web/bin/pip3 install -r $calibrewebdir/requirements.txt" >> $log 2>&1
    #fuck ldap. all my homies hate ldap
    sed '/ldap/Id' -i $calibrewebdir/optional-requirements.txt
    sudo -u ${clbWebUser} bash -c "/opt/.venv/calibre-web/bin/pip3 install -r $calibrewebdir/optional-requirements.txt" >> $log 2>&1
    echo_progress_done
}

_install_kepubify() {
    echo_progress_start "Installing kepubify"
    wget -q "https://github.com/pgaskin/kepubify/releases/download/v3.1.2/kepubify-linux-64bit" -O /tmp/kepubify >> $log 2>&1
    chmod a+x /tmp/kepubify
    mv /tmp/kepubify /usr/local/bin/kepubify
    #TODO and figure out if it's needed for all cases or not
    echo_progress_done
}

_nginx_calibreweb() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Setting up nginx conf"
        bash /etc/swizzin/scripts/nginx/calibre-web.sh
        systemctl reload nginx
        echo_progress_done
    else
        echo_info "Calibre-web will be accessible on port 8083"
    fi
}

_systemd_calibreweb() {
    echo_progress_start "Creating and enabling systemd services"
    cat > /etc/systemd/system/calibre-web.service << EOF
[Unit]
Description=Calibre-Web

[Service]
User=$clbWebUser
Type=simple
ExecStart=/opt/.venv/calibre-web/bin/python3 $calibrewebdir/cps.py -f
WorkingDirectory=$calibrewebdir
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/opt/.venv/calibre-web/bin

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload -q 2>&1 | tee -a $log
    systemctl enable -q --now calibre-web.service 2>&1 | tee -a $log
    echo_progress_done
}

_post_libdir() {
    if [[ -e "$CALIBRE_LIBRARY_PATH" ]]; then
        echo_progress_start "Setting Library to $CALIBRE_LIBRARY_PATH"
        sleep 5 # TODO replace with an actual timeout
        curl -sk 'http://127.0.0.1:8083/basicconfig' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' --compressed -H 'Content-Type: application/x-www-form-urlencoded' -H 'Connection: keep-alive' \
            --data-urlencode "config_calibre_dir=$CALIBRE_LIBRARY_PATH" \
            --data-urlencode "submit=" >> "$log" || {
            echo_warn "Setting failed, please configure your calibre library path manually in the web interface"
        }
        echo_progress_done "Library set"
    else
        echo_warn "Please configure your calibre library manually in the web interface"
    fi
}

_post_changepass() {
    : #This is where the admin password will be changed
    echo_warn "Continue the configuration and installation of Calibre-web through the browser
CHANGE THESE IMMEDIATELY --> user:admin password:admin123  <-- CHANGE THESE IMMEDIATELY"
}

_install_dependencies_calibreweb
_install_calibreweb
_install_kepubify
_systemd_calibreweb
_nginx_calibreweb
_post_libdir
_post_changepass

touch /install/.calibre-web.lock
echo_success "Calibre-web installed"
echo_docs "applications/calibre-web#post-install"

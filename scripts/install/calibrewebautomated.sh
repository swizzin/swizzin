#!/bin/bash
# Calibre-Web Automated (CWA) installer for swizzin
# Mirrors existing calibreweb installer but installs CWA into a separate path

calibrewebdir="/opt/calibrewebautomated"
clbWebUser="calibrewebautomated"

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils

if [ -z "$CALIBRE_LIBRARY_USER" ]; then
    if ! CALIBRE_LIBRARY_USER="$(swizdb get calibre/library_user)"; then
        CALIBRE_LIBRARY_USER=$(_get_master_username)
        swizdb set "calibre/library_user" "$CALIBRE_LIBRARY_USER"
    fi
else
    echo_info "Setting calibre/library_user = $CALIBRE_LIBRARY_USER"
    swizdb set "calibre/library_user" "$CALIBRE_LIBRARY_USER"
fi

if [ -z "$CALIBRE_LIBRARY_PATH" ]; then
    if ! CALIBRE_LIBRARY_PATH="$(swizdb get calibre/library_path)"; then
        CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
        swizdb set "calibre/library_path" "$CALIBRE_LIBRARY_PATH"
    fi
else
    echo_info "Setting calibre/library_path = $CALIBRE_LIBRARY_PATH"
    swizdb set "calibre/library_path" "$CALIBRE_LIBRARY_PATH"
fi

if [[ ! -f /install/.calibre.lock ]]; then
    if [ ! -e "$CALIBRE_LIBRARY_PATH" ]; then
        echo_warn "Calibre not installed, and no alternative library path is specified."
        echo_info "While having a calibre library is functionally required to use CWA, the installer will not fail without it. You can create a calibre library later."
        if ask "Install Calibre through swizzin now?" Y; then
            bash /etc/swizzin/scripts/install/calibre.sh || {
                echo_info "Installer failed, please try again"
                exit 1
            }
        fi
    fi
fi

function _install_dependencies_cwa() {
    apt_install unzip imagemagick inotify-tools
}

function _install_cwa() {
    apt_install python3-pip python3-dev python3-venv
    mkdir -p /opt/.venv/calibrewebautomated
    echo_progress_start "Creating venv for CWA"
    python3 -m venv /opt/.venv/calibrewebautomated
    echo_progress_done "Venv created"

    echo_progress_start "Downloading Calibre-Web Automated (CWA) source code archive"
    dlurl=$(curl -s https://api.github.com/repos/crocodilestick/Calibre-Web-Automated/releases/latest | jq -r '.zipball_url') || {
        echo_error "Failed to query github"
        exit 1
    }

    wget -q "${dlurl}" -O /tmp/cwa.zip >> $log 2>&1 || {
        echo_error "Failed to download source code"
        exit 1
    }

    echo_progress_done

    echo_progress_start "Extracting archive"
    unzip /tmp/cwa.zip -d /tmp/cwadir >> $log 2>&1
    subdir=$(ls /tmp/cwadir)
    mv /tmp/cwadir/"$subdir" $calibrewebdir
    echo_progress_done

    echo_progress_start "Creating users and setting permissions"
    useradd $clbWebUser --system -d "$calibrewebdir" >> $log 2>&1
    chown -R $clbWebUser:$clbWebUser $calibrewebdir
    chown -R ${clbWebUser}: /opt/.venv/calibrewebautomated
    usermod -a -G "${CALIBRE_LIBRARY_USER}" $clbWebUser >> $log 2>&1
    echo_progress_done

    echo_progress_start "Installing python dependencies"
    sudo -u ${clbWebUser} bash -c "/opt/.venv/calibrewebautomated/bin/pip3 install -r $calibrewebdir/requirements.txt" >> $log 2>&1
    sed '/ldap/Id' -i $calibrewebdir/optional-requirements.txt
    sudo -u ${clbWebUser} bash -c "/opt/.venv/calibrewebautomated/bin/pip3 install -r $calibrewebdir/optional-requirements.txt" >> $log 2>&1
    echo_progress_done
}

_install_kepubify() {
    echo_progress_start "Installing kepubify"
    wget -q "https://github.com/pgaskin/kepubify/releases/download/v3.1.2/kepubify-linux-64bit" -O /tmp/kepubify >> $log 2>&1
    chmod a+x /tmp/kepubify
    mv /tmp/kepubify /usr/local/bin/kepubify
    echo_progress_done
}

_nginx_cwa() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Setting up nginx conf for CWA"
        bash /etc/swizzin/scripts/nginx/calibrewebautomated.sh
        systemctl reload nginx
        echo_progress_done
    else
        echo_info "Calibre-Web Automated (CWA) will be accessible on port 8083"
    fi
}

_systemd_cwa() {
    echo_progress_start "Creating and enabling systemd services for CWA"
    cat > /etc/systemd/system/calibrewebautomated.service << EOF
[Unit]
Description=calibrewebautomated

[Service]
User=$clbWebUser
Type=simple
ExecStart=/opt/.venv/calibrewebautomated/bin/python3 $calibrewebdir/cps.py
WorkingDirectory=$calibrewebdir
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/opt/.venv/calibrewebautomated/bin

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload -q 2>&1 | tee -a $log
    systemctl enable -q --now calibrewebautomated.service 2>&1 | tee -a $log
    echo_progress_done
}

_post_libdir_cwa() {
    if [[ ! -e "$CALIBRE_LIBRARY_PATH" ]]; then
        echo_warn "Calibre library path either not set, or path does not exist. Please configure your calibre library manually in the CWA web interface"
        return 1
    fi

    echo_progress_start "Setting Library to $CALIBRE_LIBRARY_PATH for CWA"

    timeout 25 bash -c 'while [[ "$(curl -q -L --insecure -s -o /dev/null -w ''%{http_code}'' http://127.0.0.1:8083)" != "200" ]]; do sleep 1; echo_log_only "waiting on CWA to come up..."; done' || {
        echo_log_only "Timed out"
        return 1
    }
    curl -s -k 'http://127.0.0.1:8083/basicconfig' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' --compressed -H 'Content-Type: application/x-www-form-urlencoded' -H 'Connection: keep-alive' \
        --data-urlencode "config_calibre_dir=$CALIBRE_LIBRARY_PATH" \
        --data-urlencode "submit=" >> "$log" || {
        echo_log_only "curl failed"
        return 1
    }
    echo_progress_done "Library set"
}

_post_changepass_cwa() {
    sleep 5
    pass="$(_get_user_password "${CALIBRE_LIBRARY_USER}")"
    /opt/.venv/calibrewebautomated/bin/python3 $calibrewebdir/cps.py -s admin:"${pass}" >> "$log" 2>&1 || {
        echo_info "Could not change password, please use admin:admin123 to log in and change credentials immediately."
        return 1
    }
    echo_info "Please use the username \"admin\" (literally that, NOT your master username) and the password of $CALIBRE_LIBRARY_USER to log in to CWA"
}

_install_dependencies_cwa
_install_cwa
_install_kepubify
_systemd_cwa
_nginx_cwa
_post_libdir_cwa || {
    echo_warn "CWA did not start within time, please set Library path manually in web interface"
}
_post_changepass_cwa

touch /install/.calibrewebautomated.lock
echo_success "Calibre-Web Automated (CWA) installed"
echo_docs "applications/calibrewebautomated#post-install"

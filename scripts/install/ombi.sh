#!/bin/bash
# Ombi installer
# Swizzin gplv3 and all that

function _sources() {
    echo_progress_start "Installing ombi apt sources"
    if [[ "$(_os_distro)" == "debian" ]] && [[ "$(_os_codename)" == "trixie" ]]; then
        # Ombi's repo currently serves unsigned metadata rejected by apt on trixie.
        # Keep apt-based installs working here while preserving signed-by flow elsewhere.
        echo "deb [trusted=yes] https://apt.ombi.app/master jessie main" > /etc/apt/sources.list.d/ombi.list
        echo_warn "Using trusted Ombi repository on Debian trixie due to upstream unsigned metadata."
    else
        echo "deb [signed-by=/usr/share/keyrings/ombi-archive-keyring.gpg] https://apt.ombi.app/master jessie main" > /etc/apt/sources.list.d/ombi.list
        curl -s https://apt.ombi.app/pub.key | gpg --dearmor > /usr/share/keyrings/ombi-archive-keyring.gpg 2>> ${log}
    fi
    echo_progress_done "Sources installed"
    apt_update
}

function _install() {
    echo_progress_start "Installing Ombi runtime dependencies"
    icu_pkg="$(apt-cache search '^libicu[0-9]+$' | awk '{print $1}' | sort -Vr | sed -n '1p')"
    if [[ -n "${icu_pkg}" ]]; then
        apt_install "${icu_pkg}"
    else
        # Fallback for older or unusual apt metadata where versioned runtime package is not listed.
        apt_install libicu-dev
    fi
    echo_progress_done "Dependencies installed"

    apt_install ombi

    mkdir -p /etc/systemd/system/ombi.service.d
    cat > /etc/systemd/system/ombi.service.d/override.conf << CONF
[Service]
ExecStart=
ExecStart=/opt/Ombi/Ombi --host http://0.0.0.0:3000 --storage /etc/Ombi
CONF
    systemctl daemon-reload
    systemctl enable --now -q ombi
}

function _nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /usr/local/bin/swizzin/nginx/ombi.sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    else
        echo_info "Ombi is accessible under port 3000"
    fi

}

_sources
_install
_nginx
touch /install/.ombi.lock
echo_success "Ombi installed"
echo_info "Please continue setting up your administrator user through the browser"

#!/bin/bash
if [[ ! -f /install/.ombi.lock ]]; then
    echo_error "Ombi not installed"
    exit 1
fi

if ! grep -q apt.ombi.app /etc/apt/sources.list.d/ombi.list; then

    echo_info "Upgrading ombi apt sources"
    curl -sSL https://apt.ombi.app/pub.key | gpg --dearmor > /usr/share/keyrings/ombi-archive-keyring.gpg 2>> "${log}"
    echo "deb [signed-by=/usr/share/keyrings/ombi-archive-keyring.gpg] https://apt.ombi.app/master jessie main" > /etc/apt/sources.list.d/ombi.list

    echo_progress_start "Backing up old Ombi config and database"
    mkdir -p /root/swizzin/backups/ombiv3
    cp -R /etc/Ombi /root/swizzin/backups/ombivx
    echo_progress_done "Backed up to /root/swizzin/backups/ombivx"

    apt_update
    apt_install ombi
    if [[ -f /install/.nginx.lock ]]; then
        bash /etc/swizzin/scripts/nginx/ombi.sh
        systemctl reload nginx
    else
        echo_info "Ombi will be running on port 3000"
    fi
    echo_success "Ombi upgraded"
else
    echo_info "Please upgrade ombi through apt"
fi

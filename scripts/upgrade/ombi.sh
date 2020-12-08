#!/bin/bash
if [[ ! -f /install/.ombi.lock ]]; then
    echo_error "Ombi not installed"
    exit 1
fi

if ! grep -q roxedus.github.io /etc/apt/sources.list.d/ombi.list; then

    echo_info "Upgrading ombi to v4 sources"
    curl -sSL https://roxedus.github.io/apt-test/pub.key | apt-key add - >> "$log" 2>&1
    echo "deb https://roxedus.github.io/apt-test/develop jessie main" > /etc/apt/sources.list.d/ombi.list

    echo_progress_start "Backing up Ombi v3 config and database"
    mkdir -p /root/swizzin/backups/ombiv3
    cp -R /etc/Ombi /root/swizzin/backups/ombiv3
    echo_progress_done "Backed up to /root/swizzin/backups/ombiv3"

    apt_update
    apt_install ombi
    if [[ -f /install/.nginx.lock ]]; then
        bash /etc/swizzin/scripts/nginx/ombi.sh
        systemctl reload nginx
    else
        echo_info "Ombi will be running on port 3000"
    fi
    echo_success "Ombi upgraded to v4"
else
    echo_info "Please upgrade ombi through apt"
fi

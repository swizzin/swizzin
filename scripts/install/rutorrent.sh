#!/bin/bash
# ruTorrent installation wrapper

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "nginx does not appear to be installed, ruTorrent requires a webserver to function. Please install nginx first before installing this package."
    exit 1
fi

if [[ ! -f /install/.rtorrent.lock ]]; then
    echo_error "ruTorrent is a GUI for rTorrent, which doesn't appear to be installed. Exiting."
    exit 1
fi

bash /usr/local/bin/swizzin/nginx/rutorrent.sh || {
    echo_error "Something went wrong"
    exit 1
}

if [[ -f /install/.autodl.lock ]]; then
    echo_progress_start "Configuring Autodl Plugin"
    bash /usr/local/bin/swizzin/nginx/autodl.sh || {
        echo_error "Autodl plugin config failed."
    }
    echo_progress_done "Autodl Plugin Configured"
fi

systemctl reload nginx
echo_success "ruTorrent installed"

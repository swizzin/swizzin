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

bash /usr/local/bin/swizzin/nginx/rutorrent.sh
systemctl reload nginx
echo_success "ruTorrent installed"
touch /install/.rutorrent.lock
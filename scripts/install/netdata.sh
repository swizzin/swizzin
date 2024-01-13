#! /bin/bash
# Netdata installer for swizzin
# Author: liara

echo_progress_start "Running netdata install script"
bash <(curl -Ss https://get.netdata.cloud/kickstart.sh) --non-interactive >> $log 2>&1
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/netdata.sh
    systemctl reload nginx
    echo_progress_done
fi

echo_success "Netdata installed"
touch /install/.netdata.lock

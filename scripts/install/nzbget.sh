#!/bin/bash
# NZBGet installer for swizzin
# Author: liara
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#################################################################################

function _download() {
    echo_progress_start "Downloading install script"
    cd /tmp
    wget https://nzbget.net/download/nzbget-latest-bin-linux.run >> $log 2>&1
    echo_progress_done
}

function _service() {
    echo_progress_start "Installing systemd service"
    cat > /etc/systemd/system/nzbget@.service << NZBGD
[Unit]
Description=NZBGet Daemon
Documentation=http://nzbget.net/Documentation
After=network.target

[Service]
User=%i
Group=%i
Type=forking
ExecStart=/bin/sh -c "/home/%i/nzbget/nzbget -D"
ExecStop=/bin/sh -c "/home/%i/nzbget/nzbget -Q"
ExecReload=/bin/sh -c "/home/%i/nzbget/nzbget -O"
Restart=on-failure

[Install]
WantedBy=multi-user.target
NZBGD
    echo_progress_done
}

function _install() {
    cd /tmp
    for u in "${users[@]}"; do
        echo_progress_start "Installing nzbget for $u"
        sh nzbget-latest-bin-linux.run --destdir /home/$u/nzbget >> $log 2>&1
        chown -R $u:$u /home/$u/nzbget
        if [[ $u == $master ]]; then
            :
        else
            port=$(shuf -i 6000-7000 -n 1)
            secureport=$(shuf -i 6000-7000 -n 1)
            sed -i "s/ControlPort=6789/ControlPort=${port}/g" /home/$u/nzbget/nzbget.conf
            sed -i "s/SecurePort=6791/SecurePort=${secureport}/g" /home/$u/nzbget/nzbget.conf
        fi
        echo_progress_done "Nzbget installed for $u"
    done

    if [[ ! -d /home/$u/.ssl/ ]]; then
        mkdir -p /home/$u/.ssl/
    fi

    . /etc/swizzin/sources/functions/ssl

    create_self_ssl $u

    sed -i "s/SecureControl=no/SecureControl=yes/g" /home/$u/nzbget/nzbget.conf
    sed -i "s/SecureCert=/SecureCert=\/home\/$u\/.ssl\/$u-self-signed.crt/g" /home/$u/nzbget/nzbget.conf
    sed -i "s/SecureKey=/SecureKey=\/home\/$u\/.ssl\/$u-self-signed.key/g" /home/$u/nzbget/nzbget.conf

    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /usr/local/bin/swizzin/nginx/nzbget.sh
        systemctl reload nginx
        echo_progress_done
    else
        echo_info "Nzbget will run on port $port"
    fi

    echo_progress_start "Enabling nzbget for all users"
    for u in "${users[@]}"; do
        systemctl enable -q nzbget@$u 2>&1 | tee -a $log
        systemctl start nzbget@$u
    done
    echo_progress_done
}

function _cleanup() {
    cd /tmp
    rm -rf nzbget-latest-bin-linux.run
}

users=($(cut -d: -f1 < /etc/htpasswd))
master=$(cut -d: -f1 < /root/.master.info)
noexec=$(grep "/tmp" /etc/fstab | grep noexec)

if [[ -n $noexec ]]; then
    mount -o remount,exec /tmp
    noexec=1
fi

if [[ -n $1 ]]; then
    users=($1)
    _download
    _install
    _cleanup
    exit 0
fi

_download
_service
_install
_cleanup
echo_success "Nzbget installed"
touch /install/.nzbget.lock

if [[ -n $noexec ]]; then
    mount -o remount,noexec /tmp
fi

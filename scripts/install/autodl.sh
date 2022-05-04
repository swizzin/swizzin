#!/bin/bash
#
# [Swizzin :: Install AutoDL-IRSSI package]
#
# Originally written for QuickBox
# Ported from QuickBox and modified for Swizzin by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
#
#   QuickBox.IO does not grant the end-user the right to distribute this
#   code in a means to supply commercial monetization. If you would like
#   to include QuickBox in your commercial project, write to echo@quickbox.io
#   with a summary of your project as well as its intended use for moentization.
#

_string() { perl -le 'print map {(a..z,A..Z,0..9)[rand 62] } 0..pop' 15; }

function _installautodl() {
    apt_install irssi screen unzip libarchive-zip-perl libnet-ssleay-perl libhtml-parser-perl libxml-libxml-perl libjson-perl libjson-xs-perl libxml-libxslt-perl
}

function _autoconf() {
    echo_progress_start "Downloading autodl source code"
    curl -sL http://git.io/vlcND | grep -Po '(?<="browser_download_url":).*?[^\\].zip"' | sed 's/"//g' | xargs wget -O /tmp/autodl-irssi.zip --quiet
    echo_progress_done "Download finished"
    for u in "${users[@]}"; do
        echo_progress_start "Configuring autodl for $u"
        IRSSI_PASS=$(_string)
        IRSSI_PORT=$(shuf -i 20000-61000 -n 1)
        newdir="/home/${u}/.irssi/scripts/autorun/"
        mkdir -p "$newdir" >> "${log}" 2>&1
        unzip -o /tmp/autodl-irssi.zip -d /home/"${u}"/.irssi/scripts/ >> "${log}" 2>&1
        cp /home/"${u}"/.irssi/scripts/autodl-irssi.pl "$newdir"
        mkdir -p "/home/${u}/.autodl" >> "${log}" 2>&1
        touch "/home/${u}/.autodl/autodl.cfg"
        cat > "/home/${u}/.autodl/autodl.cfg" << ADC
[options]
gui-server-port = ${IRSSI_PORT}
gui-server-password = ${IRSSI_PASS}
ADC
        chown -R $u: /home/${u}/.autodl/
        chown -R $u: /home/${u}/.irssi/
        echo_progress_done "Autodl for $u configured"
    done
    rm /tmp/autodl-irssi.zip
    if [[ -f /install/.nginx.lock ]]; then
        bash /usr/local/bin/swizzin/nginx/autodl.sh
    fi
}

function _autoservice() {
    echo_progress_start "Creating systemd service"
    cat > "/etc/systemd/system/irssi@.service" << ADC
[Unit]
Description=AutoDL IRSSI
After=network.target

[Service]
Type=forking
KillMode=none
User=%i
ExecStart=/usr/bin/screen -d -m -fa -S irssi /usr/bin/irssi
ExecStop=/usr/bin/screen -S irssi -X stuff '/quit\n'
WorkingDirectory=/home/%i/

[Install]
WantedBy=multi-user.target
ADC

    for u in "${users[@]}"; do
        systemctl enable -q --now irssi@${u} 2>&1 | tee -a $log
    done
    echo_progress_done
}

users=($(cut -d: -f1 < /etc/htpasswd))

if [[ -n $1 ]]; then
    users=($1)
    _autoconf
    systemctl enable --now irssi@${users[0]}
    exit 0
fi

_installautodl
_autoconf
_autoservice
touch /install/.autodl.lock
echo_success "autodl installed"

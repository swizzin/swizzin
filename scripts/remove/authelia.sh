#!/bin/bash
#
# |& was added to Bash 4 as an abbreviation for 2>&1 |. - https://tldp.org/LDP/abs/html/io-redirection.html
#
if [[ ! -f /install/.authelia.lock ]]; then
    echo_warn "Authelia is not installed"
    exit 1
else
    systemctl disable -q --now authelia &>> "${log}"
    rm -rf /etc/authelia
    rm -rf /opt/authelia
    echo_progress_done "Done"
fi
#
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Removing Authelia from nginx"
    rm -f /etc/nginx/apps/authelia.conf
    rm -rf /etc/nginx/apps/authelia
    systemctl reload -q nginx &>> "${log}"
    echo_progress_done "Done"
fi

rm -f /install/.authelia.lock

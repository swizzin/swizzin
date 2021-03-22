#!/bin/bash
. /etc/swizzin/sources/functions/os
if [[ -f /install/.requestrr.lock ]]; then
    echo_info "Upgrading Requestrr"
    systemctl disable --now requestrr
    echo_progress_start "Downloading source files"
    case "$(_os_arch)" in
        "amd64") dlurl=$(curl -sNL https://api.github.com/repos/darkalfx/requestrr/releases/latest | grep -Po 'ht(.*)linux-x64(.*)zip') >> ${log} 2>&1 ;;
        "armhf") dlurl=$(curl -sNL https://api.github.com/repos/darkalfx/requestrr/releases/latest | grep -Po 'ht(.*)linux-arm(.*)zip') >> ${log} 2>&1 ;;
        "arm64") dlurl=$(curl -sNL https://api.github.com/repos/darkalfx/requestrr/releases/latest | grep -Po 'ht(.*)linux-arm64(.*)zip') >> ${log} 2>&1 ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    curl "$dlurl" -L -o /tmp/requestrr.zip >> "$log" 2>&1 || {
        echo_error "Download failed, exiting"
        exit 1
    }
    echo_progress_done "Source downloaded"
    echo_progress_start "Replacing source code"

    unzip -q /tmp/requestrr.zip -d /tmp/ >> "$log" 2>&1
    rm /tmp/requestrr.zip
    cp -RT /tmp/requestrr*/ /opt/requestrr
    chown -R requestrr:requestrr /opt/requestrr
    rm -rf /tmp/requestrr*
    echo_progress_done "Extracted and overwrote existing files."

    echo_progress_start "Patching config"
    if [[ -f /install/.nginx.conf ]]; then
        bash /usr/local/bin/swizzin/nginx/requestrr.sh
        systemctl -q reload nginx
    fi
    echo_progress_done "Config patched"

    echo_progress_start "Restarting services"
    systemctl daemon-reload
    systemctl -q enable --now requestrr
    echo_progress_done "Requestrr has been updated."
fi

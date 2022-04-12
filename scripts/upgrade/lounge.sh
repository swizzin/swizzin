#!/usr/bin/env bash

function _yarnlounge() {
    #shellcheck source=sources/functions/npm
    . /etc/swizzin/sources/functions/npm

    if [[ $active == "active" ]]; then
        systemctl stop lounge
    fi
    npm uninstall -g thelounge --save >> /dev/null 2>&1
    yarn_install
    yarn --non-interactive global add thelounge >> $log 2>&1
    yarn --non-interactive cache clean >> $log 2>&1
    if [[ $active == "active" ]]; then
        systemctl start lounge
    fi
}

if [[ ! -f /install/.lounge.lock ]]; then
    echo "lounge does not appear to be installed!"
    exit 1
fi

if [[ $(systemctl is-active lounge) == "active" ]]; then
    wasActive="true"
    echo_progress_start "Shutting down lounge"
    systemctl stop lounge
    echo_progress_done
fi

if thelounge --version lt 4.3.1; then

    _yarnlounge
fi

if ! yarn --non-interactive global upgrade thelounge >> "$log"; then
    echo_error "Lounge failed to update, please investigate the logs"
fi

if [[ $wasActive = "true" ]]; then
    echo_progress_start "Restarting lounge"
    systemctl start lounge
    echo_progress_done
fi

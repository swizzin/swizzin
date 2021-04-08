#!/usr/bin/env bash
#
if [[ ! -f /install/.authelia.lock ]]; then
    echo_warn "Authelia is not installed"
    exit 1
else
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    #shellcheck source=sources/functions/os
    . /etc/swizzin/sources/functions/os

    echo_progress_start "Updating Authelia"
    systemctl stop -q authelia &>> "${log}"
    # Get the current version using a git ls-remote tag check
    authelia_latestv="$(git ls-remote -t --refs https://github.com/authelia/authelia.git | awk '{sub("refs/tags/", "");sub("(.*)-alpha(.*)", ""); print $2 }' | awk '!/^$/' | sort -rV | head -n1)"
    # Create the download url using the version provided by authelia_latestv
    case "$(_os_arch)" in
        "amd64") authelia_arch="amd64" ;;
        "armhf") authelia_arch="arm32v7" ;;
        "arm64") authelia_arch="arm64v8" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac
    #
    authelia_url="https://github.com/authelia/authelia/releases/download/${authelia_latestv}/authelia-linux-${authelia_arch}.tar.gz"
    mkdir -p "/opt/authelia"
    wget -qO "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" "${authelia_url}"
    tar -xf "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" -C "/opt/authelia/" "authelia-linux-${authelia_arch}"
    ln -fsn "/opt/authelia/authelia-linux-${authelia_arch}" "/opt/authelia/authelia"
    rm_if_exists "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz"
    systemctl start -q authelia &>> "${log}"
    echo_progress_done "Authelia updated and restarted"

    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Updating nginx config"
        bash "/usr/local/bin/swizzin/nginx/authelia.sh"
        systemctl reload nginx
        echo_progress_done "Nginx config installed"
    fi
fi

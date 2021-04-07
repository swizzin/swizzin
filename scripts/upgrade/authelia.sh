#!/bin/bash
#
if [[ ! -f /install/.authelia.lock ]]; then
    echo_warn "Authelia is not installed"
    exit 1
else
    echo_progress_start "Updating Authelia"
    systemctl stop -q authelia |& tee -a $log
    #
    . /etc/swizzin/sources/functions/os
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
    # Create the loction for the stored binary
    mkdir -p "/opt/authelia"
    # Download the binary
    wget -qO "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" "${authelia_url}"
    # Extract the specific file we need and nothing else.
    tar -xf "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" -C "/opt/authelia/" "authelia-linux-${authelia_arch}"
    # Symlink the extracted binary authelia-linux-${authelia_arch} to authelia
    ln -fsn "/opt/authelia/authelia-linux-${authelia_arch}" "/opt/authelia/authelia"
    # Remove the archive we no longer need
    [[ -f "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz" ]] && rm -f "/opt/authelia/authelia-linux-${authelia_arch}.tar.gz"
    #
    systemctl start -q authelia |& tee -a $log
    echo_progress_done "Authelia updated and restarted"

    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Updating nginx config"
        bash "/usr/local/bin/swizzin/nginx/authelia.sh"
        systemctl reload nginx
        echo_progress_done "Nginx config installed"
    fi
fi

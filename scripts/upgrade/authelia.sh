#!/bin/bash
#
if [[ ! -f /install/.authelia.lock ]]; then
    echo_warn "Authelia is not installed"
    exit 1
else
    echo_progress_start "Updating Authelia"
    systemctl stop -q authelia |& tee -a $log
    # Set the current version using a git ls-remote tag check
    authelia_latestv="$(git ls-remote -t --sort=-v:refname --refs https://github.com/authelia/authelia.git | awk '{sub("refs/tags/", "");sub("(.*)-alpha(.*)", ""); print $2 }' | head -n1)"
    # Create the download url using the version provided by authelia_latestv
    authelia_url="https://github.com/authelia/authelia/releases/download/${authelia_latestv}/authelia-linux-amd64.tar.gz"
    # Create the loction for the stored binary
    mkdir -p "/opt/authelia"
    # Download the binary
    wget -qO "/opt/authelia/authelia-linux-amd64.tar.gz" "${authelia_url}"
    # Extract the specific file we need and nothing else.
    tar -xf "/opt/authelia/authelia-linux-amd64.tar.gz" -C "/opt/authelia/" 'authelia-linux-amd64'
    # Symlink the extracted binary authelia-linux-amd64 to authelia
    ln -fsn "/opt/authelia/authelia-linux-amd64" "/opt/authelia/authelia"
    # Remove the archive we no longer need
    [[ -f "/opt/authelia/authelia-linux-amd64.tar.gz" ]] && rm -f "/opt/authelia/authelia-linux-amd64.tar.gz"
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

#!/bin/bash
# flying sausages swizzin 2021 gplv3 yadda yadda

_install() {
    echo_progress_start "Downloading binary"

    giturl="https://api.github.com/repos/varbhat/exatorrent/releases/latest"
    case "$(_os_arch)" in
        "arm64") ;;
        "amd64") ;;
        *)
            echo_error "Unsupported architecture"
            exit 1
            ;;
    esac
    dlurl=$(curl -s "$giturl" | jq -r '.assets[]?.browser_download_url' | grep "$(_os_arch)") || {
        echo_error "Failed to query github"
        exit 1
    }
    wget "$dlurl" -O /tmp/exatorrent &> $log || {
        echo_error "Download failed"
        exit 1
    }

    grep -q "ELF" <<< "$(file /tmp/exatorrent)" || {
        # Checking if download file is actually a binary that can run without running it
        echo_error "Failed to download complete binary"
        exit 1
    }

    mv /tmp/exatorrent /opt/exatorrent
    chown -R root: /opt/exatorrent
    chmod -R a+rx /opt/exatorrent # All users can browse and exec
    chmod -R og-w /opt/exatorrent # Only owner can overwrite

    echo_progress_done "Binary downloaded"
}

_systemd() {
    cat > /etc/systemd/system/exatorrent@.service << SYSD
# Service file example for exatorrent
[Unit]
Description=exatorrent - let's fucking go torrents yea
After=network.target

[Service]
User=%i
EnvironmentFile=/home/%i/exatorrent/config/.env
ExecStart=/opt/exatorrent -dir /home/%i/exatorrent -admin %i -addr :\${EXAWEBPORT}
Restart=on-abort
TimeoutSec=20

[Install]
WantedBy=multi-user.target
SYSD
}

_userconf() {
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils # used for port

    for user in "${users[@]}"; do
        echo_progress_start "Configuring exatorrent for $user"

        exadir="/home/$user/exatorrent"
        mkdir -p "$exadir"
        clientconfig="$exadir/config/clientconfig.json"
        engconfig="$exadir/config/engconfig.json"
        flagconfig="$exadir/config/flagconfig.json"
        webport=$(port 10001 20000)
        cat > "$exadir"/config/.env << ENV
EXAWEBPORT='$webport'
ENV

        rm -rf "$clientconfig" "$engconfig" "$flagconfig"
        /opt/exatorrent -dir "$exadir" -engc &> $log || {
            echo_error "Failed to create engine config"
            exit 1
        }
        /opt/exatorrent -dir "$exadir" -torc &> $log || {
            echo_error "Failed to create client config"
            exit 1
        }

        # torrent engine settings
        peerport="$(port 5000 10000)"
        cat <<< "$(jq --arg PORT "$peerport" '.ListenPort = ($PORT|tonumber)' "$clientconfig")" > "$clientconfig" # Peer listening port
        cat <<< "$(jq '.NoDHT = true' "$clientconfig")" > "$clientconfig"
        cat <<< "$(jq '.DisablePEX = true' "$clientconfig")" > "$clientconfig"
        cat <<< "$(jq '.DisableTrackers = true' "$clientconfig")" > "$clientconfig" # Disables automatically adding a list of trackers to loaded torrents

        # exatorrent settings
        cat <<< "$(jq '.disableonlinecache = true' "$engconfig")" > "$engconfig"
        cat <<< "$(jq '.disallowtrackersforcache = true' "$engconfig")" > "$engconfig"

        # TODO change password, but where?
        # cat <<< "$(jq --arg PASS "$(_get_user_password "$user")" '.ListenPort = $PORT' "$clientconfig")" > "$clientconfig" # Peer listening port
        # cat <<< "$(jq --arg USER "$user" '.AdminUsername = $PORT' "$engconfig")" > "$engconfig" # Peer listening port

        chown -R "$user": "$exadir"
        echo_progress_done "Exatorrent for $user started"
    done

}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/exatorrent.sh
        systemctl reload nginx
        echo_progress_done "nginx configured"
    else
        echo_info "exatorrent will run on ports defined in each user's \"exatorrent\" folder's .env file"
    fi
}

if [[ -n $1 ]]; then
    users=("$1")
    _userconf
    _nginx
    exit 1
fi

_install
_systemd
readarray -t users < <(_get_user_list)
_userconf
_nginx

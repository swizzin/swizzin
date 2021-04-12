#!/bin/bash
_queries() {
    if [ -z "$PLEX_SERVER" ]; then
        if [[ ! -f /install/.plex.lock ]]; then
            echo_warn "Plex server not installed"
            echo_query "Please enter your Plex Server's address (e.g. domain.ltd:32400)"
            read -r PLEX_SERVER
        else
            PLEX_SERVER="localhost:32400"
        fi
    else
        echo_info "Environment variable PLEX_SERVER set to $PLEX_SERVER"
    fi

    if [ -z "$PLEX_TOKEN" ]; then
        echo_info "Moviematch needs to connect to Plex via a Token. You can hear how to retrieve one here:\nhttps://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/"
        echo_query "Please enter your Plex Token"
        read -r PLEX_TOKEN
    else
        echo_info "Environment variable PLEX_TOKEN set to $PLEX_TOKEN"
    fi
}

mmatchDir="/opt/moviematch"

_install_moviematch() {

    echo_progress_start "Cloning moviematch"
    git clone https://github.com/LukeChannings/moviematch.git $mmatchDir >> $log
    echo_progress_done "Repo cloned"

    chmod +x $mmatchDir
    chmod o+rx -R $mmatchDir

    useradd moviematch --system -d "$mmatchDir" >> $log 2>&1
    sudo chown -R moviematch:moviematch $mmatchDir

    echo_progress_done "Binary downloaded and extracted"

    cat > $mmatchDir/config.yaml << ENV
port: 8420
servers:
  - url: http://$PLEX_SERVER
    token: $PLEX_TOKEN
ENV
}

_systemd() {

    echo_progress_start "Installing systemd service and starting moviematch"
    cat > /etc/systemd/system/moviematch.service << SYSTEMD
[Unit]
Description=Moviematch
Documentation=https://swizzin.ltd/applications/moviematch
After=network.target

[Service]
Type=simple
User=moviematch
WorkingDirectory=${mmatchDir}
ExecStart=/usr/local/bin/deno run --allow-net --allow-read --allow-env --unstable ${mmatchDir}/src/index.ts
Restart=on-failure

[Install]
WantedBy=multi-user.target
SYSTEMD
    systemctl daemon-reload
    systemctl enable --now -q moviematch
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        # echo_info "Moviematch is available on port 8420\n(NGINX/baseurl support coming via box update when this issue gets resolved upstream https://github.com/LukeChannings/moviematch/issues/10)"
        # TODO change baseurl config when issue above is fixed
        bash /etc/swizzin/scripts/nginx/moviematch.sh
        systemctl reload nginx
    else
        echo_info "Moviematch is available on port 8420"
    fi
}

_queries
_install_deno
_install_moviematch
_systemd
_nginx

touch /install/.moviematch.lock
echo_success "Moviematch installed"
# deno run --allow-net --allow-read --allow-env $mmatchDir/src/index.ts

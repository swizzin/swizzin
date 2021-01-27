#!/bin/bash
if [[ -f /install/.radarr.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/radarr

    #Move radarr installs to v3.net
    if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/radarr.service; then
        echo_info "Moving Radarr from mono to .Net"
        #shellcheck source=sources/functions/utils
        . /etc/swizzin/sources/functions/utils
        [[ -z $radarrOwner ]] && radarrOwner=$(_get_master_username)

        if [[ $(_radarr_version) = "mono-v3" ]]; then
            echo_progress_start "Downloading source files"
            if ! curl "https://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64" -L -o /tmp/Radarr.tar.gz >> "$log" 2>&1; then
                echo_error "Download failed, exiting"
                exit 1
            fi
            echo_progress_done "Source downloaded"

            isactive=$(systemctl is-active radarr)
            echo_log_only "Radarr was $isactive"
            [[ $isactive == "active" ]] && systemctl stop radarr -q

            echo_progress_start "Extracting archive"
            rm /opt/Radarr/Radarr.exe
            tar -xvf /tmp/Radarr.tar.gz -C /opt >> "$log" 2>&1
            chown -R "$radarrOwner":"$radarrOwner" /opt/Radarr
            echo_progress_done "Archive extracted"

            echo_progress_start "Fixing Radarr systemd service"
            # Watch out! If this sed runs, the updater will not trigger anymore. keep this at the bottom.
            sed -i "s|ExecStart=/usr/bin/mono /opt/Radarr/Radarr.exe|ExecStart=/opt/Radarr/Radarr|g" /etc/systemd/system/radarr.service
            systemctl daemon-reload
            [[ $isactive == "active" ]] && systemctl start radarr -q
            echo_progress_done "Service fixed and restarted"
            echo_success "Radarr upgraded to .Net"

            if [[ -f /install/.nginx.lock ]]; then
                echo_progress_start "Upgrading nginx config for Radarr"
                bash /etc/swizzin/scripts/nginx/radarr.sh
                systemctl reload nginx -q
                echo_progress_done "Nginx conf for Radarr upgraded"
            fi

        elif [[ $(_radarr_version) = "mono-v2" ]]; then
            echo_warn "Please upgrade your radarr to v3. It will be migrated to .Net core on the next \`box update\` run"
            echo_docs "applications/radarr#migrating-to-v3-on-net-core"
        fi
    fi
fi

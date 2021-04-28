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
            echo_progress_start "Downloading release files"
            urlbase="https://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore"
            case "$(_os_arch)" in
                "amd64") dlurl="${urlbase}&arch=x64" ;;
                "armhf") dlurl="${urlbase}&arch=arm" ;;
                "arm64") dlurl="${urlbase}&arch=arm64" ;;
                *)
                    echo_error "Arch not supported"
                    exit 1
                    ;;
            esac
            if ! curl "$dlurl" -L -o /tmp/radarr.tar.gz >> "$log" 2>&1; then
                echo_error "Download failed, exiting"
                exit 1
            fi
            echo_progress_done "Release downloaded"

            isactive=$(systemctl is-active radarr)
            echo_log_only "Radarr was $isactive"
            [[ $isactive == "active" ]] && systemctl stop radarr -q

            echo_progress_start "Removing old binaries"
            rm -rf /opt/Radarr/
            echo_progress_done "Binaries removed"

            echo_progress_start "Extracting archive"
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
            echo_warn "Radarr v0.2 is EOL and not supported. Please upgrade your radarr to v3. An attempt will be made to migrate to .Net core on the next \`box update\` run"
            echo_docs "applications/radarr#migrating-to-v3-on-net-core"
        fi
    fi
    #Mandatory SSL Port change for Readarr
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    app_name="radarr"
    if [ -z "$radarrOwner" ]; then
        if ! radarrOwner="$(swizdb get $app_name/owner)"; then
            radarrOwner=$(_get_master_username)
            echo_info "Setting ${app_name^} owner = $radarrOwner"
            swizdb set "$app_name/owner" "$radarrOwner"
        fi
    else
        echo_info "Setting ${app_name^} owner = $radarrOwner"
        swizdb set "$app_name/owner" "$radarrOwner"
    fi
    app_configfile="/home/$radarrOwner/.config/Radarr/config.xml"

    # Don't have grep complain if the user moved the file from the standard location
    if [ -f "$app_configfile" ]; then
        sslport=$(grep -oPm1 "(?<=<SslPort>)[^<]+" "$app_configfile")
        sslenabled=$(grep -oPm1 "(?<=<EnableSsl>)[^<]+" "$app_configfile")
        if [[ "$sslport" = "8787" ]]; then
            echo_log_only "Changing radarr ssl port"
            sed -i 's|<SslPort>8787</SslPort>|<SslPort>9898</SslPort>|g' "$app_configfile"
            systemctl try-restart -q radarr
            if [[ "$sslenabled" = "True" ]]; then
                echo "Radarr SSL port changed from 8787 to 9898 due to Readarr conflicts; please ensure to adjust your dependent systems in case they were using this port"
            fi
        fi
    else
        echo_warn "Radarr Config file not found. Please ensure you do not have the SSL Port set to 8787 as this conflicts with Readarr if Radarr SSL is enabled."
        exit
    fi
fi

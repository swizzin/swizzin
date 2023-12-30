#!/bin/bash
if [[ -f /install/.sonarr.lock ]]; then
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/sonarr

    #Move sonarr installs to .net
    if grep -q "ExecStart=/usr/bin/mono" /etc/systemd/system/sonarr.service; then
        echo_info "Moving Sonarr from mono to .Net"
        #shellcheck source=sources/functions/utils
        . /etc/swizzin/sources/functions/utils
        [[ -z $sonarrOwner ]] && sonarrOwner=$(_get_master_username)

        if [[ $(_sonarr_version) = "mono-v3" ]]; then
            echo_progress_start "Downloading release files"
            urlbase="https://services.sonarr.tv/v1/download/main/latest?version=4&os=linux"
            case "$(_os_arch)" in
                "amd64") dlurl="${urlbase}&arch=x64" ;;
                "armhf") dlurl="${urlbase}&arch=arm" ;;
                "arm64") dlurl="${urlbase}&arch=arm64" ;;
                *)
                    echo_error "Arch not supported"
                    exit 1
                    ;;
            esac
            if ! curl "$dlurl" -L -o /tmp/sonarr.tar.gz >> "$log" 2>&1; then
                echo_error "Download failed, exiting"
                exit 1
            fi
            echo_progress_done "Release downloaded"

            isactive=$(systemctl is-active sonarr)
            echo_log_only "Sonarr was $isactive"
            [[ $isactive == "active" ]] && systemctl stop sonarr -q

            echo_progress_start "Removing old binaries"
            rm -rf /opt/Sonarr/
            echo_progress_done "Binaries removed"

            echo_progress_start "Extracting archive"
            tar -xvf /tmp/sonarr.tar.gz -C /opt >> "$log" 2>&1
            chown -R "$sonarrOwner":"$sonarrOwner" /opt/Sonarr
            echo_progress_done "Archive extracted"

            echo_progress_start "Fixing Sonarr systemd service"
            # Watch out! If this sed runs, the updater will not trigger anymore. keep this at the bottom.
            sed -i "s|ExecStart=/usr/bin/mono --debug /opt/Sonarr/Sonarr.exe|ExecStart=/opt/Sonarr/Sonarr|g" /etc/systemd/system/sonarr.service
            systemctl daemon-reload
            [[ $isactive == "active" ]] && systemctl start sonarr -q
            echo_progress_done "Service fixed and restarted"
            echo_success "Sonarr upgraded to .Net"

            if [[ -f /install/.nginx.lock ]]; then
                echo_progress_start "Upgrading nginx config for Sonarr"
                bash /etc/swizzin/scripts/nginx/sonarr.sh
                systemctl reload nginx -q
                echo_progress_done "Nginx conf for Sonarr upgraded"
            fi

        elif [[ $(_sonarr_version) = "mono-v2" ]]; then
            echo_warn "Sonarr v2 is EOL and not supported. Please upgrade your Sonarr to v4. An attempt will be made to migrate to .NET on the next \`box update\` run"
            echo_docs "applications/sonarr#migrating-to-v3-on-net-core"
        fi
    else
        echo_log_only "Sonarr's service is not pointing to mono"
    fi
    #Mandatory SSL Port change for Readarr
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    app_name="sonarr"
    if [ -z "$sonarrOwner" ]; then
        if ! sonarrOwner="$(swizdb get $app_name/owner)"; then
            sonarrOwner=$(_get_master_username)
            ownerToSetInDB='True'
        fi
    else
        ownerToSetInDB='True'
    fi

    app_configfile="/home/$sonarrOwner/.config/Sonarr/config.xml"

    if [[ $ownerToSetInDB = 'True' ]]; then
        if [ -e "$app_configfile" ]; then
            echo_info "Setting ${app_name^} owner = $sonarrOwner in SwizDB"
            swizdb set "$app_name/owner" "$sonarrOwner"
        else
            echo_error "${app_name^} config file for sonarr owner does not exist in expected location.
We are checking for $app_configfile.
If the user here is incorrect, please run \`sonarrOwner=<user> box update\`.
${app_name^} updater is exiting, please try again later."
            exit 1
        fi
    else
        echo_log_only "Sonarr owner $sonarrOwner apparently did not need an update"
    fi

    if [[ -f /install/.nginx.lock ]]; then
        if grep -q "8989/sonarr" /etc/nginx/apps/sonarr.conf; then
            echo_progress_start "Upgrading nginx config for Sonarr"
            bash /etc/swizzin/scripts/nginx/sonarr.sh
            systemctl reload nginx -q
            echo_progress_done "Nginx config for Sonarr upgraded"
        fi
    fi
fi

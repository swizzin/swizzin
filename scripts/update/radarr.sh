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

    ### Populate swizdb values to defaults if empty; these must be kept in sync with install
    #ToDo: Fix this if logic; we want to check if the DB has something; if so, do nothing.. if not. populate DB with defaults
    app_name="radarr"
    if ! "$(swizdb get $app_name/app_name)"; then
        swizdb set "$app_name/name" "$app_name"
    else
        app_name=swizdb get "$app_name/name"
    fi
    if ! "$(swizdb get $app_name/dir)"; then
        app_dir="/opt/${app_name^}"
        swizdb set "$app_name/dir" "${app_dir^}"
    else
        app_dir=swizdb get "$app_name/dir"
    fi
    if ! "$(swizdb get $app_name/binary)"; then
        app_binary="${app_name^}"
        swizdb set "$app_name/binary" "${app_binary^}"
    else
        app_binary=swizdb get "$app_name/binary"
    fi
    if ! "$(swizdb get $app_name/port)"; then
        app_port="7878"
        swizdb set "$app_name/port" "$app_port"
    else
        app_port=swizdb get "$app_name/port"
    fi
    if ! "$(swizdb get $app_name/reqs)"; then
        app_reqs=("curl" "mediainfo" "sqlite3")
        swizdb set "$app_name/reqs" "${app_reqs[@]}"
    else
        app_req=swizdb get "$app_name/req"
    fi
    if ! "$(swizdb get $app_name/branch)"; then
        app_branch="master"
        swizdb set "$app_name/branch" "$app_branch"
    else
        app_branch=swizdb get "$app_name/branch"
    fi
    if ! "$(swizdb get $app_name/lockname)"; then
        app_lockname=$app_name
        swizdb set "$app_name/lockname" "$app_lockname"
    else
        app_lockname=swizdb get "$app_name/lockname"
    fi
    if ! "$(swizdb get $app_name/user)"; then
        app_user="$RADARR_OWNER"
        swizdb set "$app_name/user" "$app_user"
    else
        app_user="$(swizdb get "$app_name/user")"
    fi

    if ! "$(swizdb get $app_name/configdir)"; then
        app_configdir="/home/$app_user/.config/${app_name^}"
        swizdb set "$app_name/configdir" "$app_configdir"
    else
        app_configdir="$(swizdb get "$app_name/configdir")"
    fi
    if ! "$(swizdb get $app_name/servicename)"; then
        app_servicename="/home/$app_user/.config/${app_servicename}"
        swizdb set "$app_name/servicename" "$app_servicename"
    else
        app_servicename="$(swizdb get "$app_name/servicename")"
    fi
    if ! "$(swizdb get $app_name/servicefile)"; then
        app_configdir="/home/$app_user/.config/${app_name^}"
        swizdb set "$app_name/servicefile" "$app_servicefile"
    else
        app_servicefile="$(swizdb get "$app_name/servicefile")"
    fi
    if ! "$(swizdb get $app_name/nginxname)"; then
        app_nginxname="/home/$app_user/.config/${app_name^}"
        swizdb set "$app_name/nginxname" "$app_nginxname"
    else
        app_nginxname="$(swizdb get "$app_name/nginxname")"
    fi
    if ! "$(swizdb get $app_name/nginxname)"; then
        app_nginxname="/home/$app_user/.config/${app_name^}"
        swizdb set "$app_name/nginxname" "$app_nginxname"
    else
        app_nginxname="$(swizdb get "$app_name/nginxname")"
    fi
    if ! "$(swizdb get $app_name/urlbase)"; then
        app_urlbase="${app_name}"
        swizdb set "$app_name/urlbase" "$app_urlbase"
    else
        app_urlbase="$(swizdb get "$app_name/urlbase")"
    fi
    if ! "$(swizdb get $app_name/app_apiversion)"; then
        app_apiversion="v3"
        swizdb set "$app_name/app_apiversion" "$app_app_apiversion"
    else
        app_nginxname="$(swizdb get "$app_name/nginxname")"
    fi

    #Mandatory SSL Port change for Readarr
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils

    if [[ $ownerToSetInDB = 'True' ]]; then
        if [ -e "$app_configfile" ]; then
            echo_info "Setting ${app_name^} owner = $radarrOwner in SwizDB"
            swizdb set "$app_name/owner" "$radarrOwner"
        else
            echo_error "${app_name^} config file for radarr owner does not exist in expected location.
We are checking for $app_configfile.
If the user here is incorrect, please run \`radarrOwner=<user> box update\`.
${app_name^} updater is exiting, please try again later."
            exit 1
        fi
    else
        echo_log_only "Owner $radarrOwner apparently did not need an update"
    fi

    if grep -q "<SslPort>8787" "$app_configfile"; then
        echo_log_only "Changing radarr ssl port in line with upstream"
        sed -i 's|<SslPort>8787</SslPort>|<SslPort>9898</SslPort>|g' "$app_configfile"
        systemctl try-restart -q radarr

        if grep -q "<EnableSsl>True" "$app_configfile"; then
            echo_info "Radarr SSL port changed from 8787 to 9898 due to Readarr conflicts; please ensure to adjust your dependent systems in case they were using this port"
        fi
    fi
fi

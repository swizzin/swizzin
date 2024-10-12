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
            MONO='mono-runtime
                  ca-certificates-mono
                  libmono-system-net-http4.0-cil
                  libmono-corlib4.5-cil
                  libmono-microsoft-csharp4.0-cil
                  libmono-posix4.0-cil
                  libmono-system-componentmodel-dataannotations4.0-cil
                  libmono-system-configuration-install4.0-cil
                  libmono-system-configuration4.0-cil
                  libmono-system-core4.0-cil
                  libmono-system-data-datasetextensions4.0-cil
                  libmono-system-data4.0-cil
                  libmono-system-identitymodel4.0-cil
                  libmono-system-io-compression4.0-cil
                  libmono-system-numerics4.0-cil
                  libmono-system-runtime-serialization4.0-cil
                  libmono-system-security4.0-cil
                  libmono-system-servicemodel4.0a-cil
                  libmono-system-serviceprocess4.0-cil
                  libmono-system-transactions4.0-cil
                  libmono-system-web4.0-cil
                  libmono-system-xml-linq4.0-cil
                  libmono-system-xml4.0-cil
                  libmono-system4.0-cil'
            apt-mark auto ${MONO}
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
        if grep -q "8989/sonarr" /etc/nginx/apps/sonarr.conf || ! grep -q "proxy_read_timeout" /etc/nginx/apps/sonarr.conf; then
            echo_progress_start "Upgrading nginx config for Sonarr"
            bash /etc/swizzin/scripts/nginx/sonarr.sh
            systemctl reload nginx -q
            echo_progress_done "Nginx config for Sonarr upgraded"
        fi
    fi
fi

if dpkg -l | grep nzbdrone > /dev/null 2>&1; then
    v2present=true
    echo_warn "Sonarr v2 is obsolete and end-of-life. Please upgrade your Sonarr to v3 using \`box upgrade sonarr\`."
fi
if [[ -f /install/.sonarr.lock ]] && [[ $v2present == "true" ]]; then
    echo_info "box package sonarr is being renamed to sonarrold"
    #update lock file
    rm /install/.sonarr.lock
    if [[ -f /install/.nginx.lock ]]; then
        mv /etc/nginx/apps/sonarr.conf /etc/nginx/apps/sonarrold.conf
        systemctl reload nginx
    fi
    touch /install/.sonarrold.lock
fi
if [[ -f /install/.sonarrv3.lock ]]; then
    echo_info "box package sonarrv3 is being renamed to sonarr as it has been released as stable"
    #upgrade sonarr v3 lock
    if [[ -f /install/.nginx.lock ]]; then
        mv /etc/nginx/apps/sonarrv3.conf /etc/nginx/apps/sonarr.conf
        systemctl reload nginx
    fi
    rm /install/.sonarrv3.lock
    touch /install/.sonarr.lock
fi
if [[ -f /install/.sonarr.lock ]] && dpkg -l | grep sonarr | grep ^ii > /dev/null 2>&1; then
    echo_info "Migrating Sonarr away from apt management!"
    echo_progress_start "Migrating Sonarr away from apt management"
    isActive=$(systemctl is-active sonarr)
    isEnabled=$(systemctl is-enabled sonarr)
    cp -a /usr/lib/sonarr/bin /opt/Sonarr
    if [[ ! -f /lib/systemd/system/sonarr.service ]]; then
        echo_error "A required file for the update could not be found: /lib/systemd/system/sonarr.service . Is your current Sonarr installation in a proper state?"
        exit 1
    fi
    cp /lib/systemd/system/sonarr.service /etc/systemd/system
    user=$(grep User= /etc/systemd/system/sonarr.service | cut -d= -f2)
    if [[ -z ${user} ]]; then
        echo_error "Could not determine the owner of Sonarr"
        exit 1
    fi
    echo_info "Moving config to '/home/${user}/.config/Sonarr'"
    mv /home/${user}/.config/sonarr /home/${user}/.config/Sonarr

    #Remove comments
    sed -i '/^#/d' /etc/systemd/system/sonarr.service
    #Update binary location
    sed -i 's|/usr/lib/sonarr/bin|/opt/Sonarr|g' /etc/systemd/system/sonarr.service
    sed -i "s|/home/${user}/.config/sonarr|/home/${user}/.config/Sonarr|g" /etc/systemd/system/sonarr.service

    #Mark depends as manually installed
    LIST='mono-runtime
        ca-certificates-mono
        libmono-system-net-http4.0-cil
        libmono-corlib4.5-cil
        libmono-microsoft-csharp4.0-cil
        libmono-posix4.0-cil
        libmono-system-componentmodel-dataannotations4.0-cil
        libmono-system-configuration-install4.0-cil
        libmono-system-configuration4.0-cil
        libmono-system-core4.0-cil
        libmono-system-data-datasetextensions4.0-cil
        libmono-system-data4.0-cil
        libmono-system-identitymodel4.0-cil
        libmono-system-io-compression4.0-cil
        libmono-system-numerics4.0-cil
        libmono-system-runtime-serialization4.0-cil
        libmono-system-security4.0-cil
        libmono-system-servicemodel4.0a-cil
        libmono-system-serviceprocess4.0-cil
        libmono-system-transactions4.0-cil
        libmono-system-web4.0-cil
        libmono-system-xml-linq4.0-cil
        libmono-system-xml4.0-cil
        libmono-system4.0-cil
        sqlite3
        mediainfo'

    apt_install ${LIST}

    apt_remove --purge sonarr
    rm -rf /var/lib/sonarr
    rm -rf /usr/lib/sonarr
    rm -f /etc/apt/sources.list.d/sonarr.list*
    systemctl daemon-reload

    #Restart sonarr because apt-removal stops it
    if [[ $isActive == "active" ]]; then
        systemctl start sonarr
    fi

    #Update broken symlink to old service
    if [[ $isEnabled == "enabled" ]]; then
        systemctl enable sonarr >> ${log} 2>&1
    fi
    echo_progress_done
fi

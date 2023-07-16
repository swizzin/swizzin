#!/usr/bin/env bash
#
if [[ -f /install/.jellyfin.lock ]]; then
    # awaiting pull to remove
    function dist_info() {
        DIST_CODENAME="$(source /etc/os-release && echo "$VERSION_CODENAME")"
        DIST_ID="$(source /etc/os-release && echo "$ID")"
    }
    # source the functions we need for this script.
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    # Get our main user credentials using a util function.
    username="$(_get_master_username)"
    dist_info # get our distribution ID, set to DIST_ID, and VERSION_CODENAME, set to DIST_CODENAME, from /etc/os-release
    #
    # remove the old service and remove legacy files.
    if [[ -f /etc/systemd/system/jellyfin.service ]]; then
        echo_progress_start "Removing old Jellyfin service"
        systemctl -q disable --now jellyfin.service
        rm_if_exists /etc/systemd/system/jellyfin.service
        kill -9 $(ps xU "${username}" | grep "/opt/jellyfin/jellyfin -d /home/${username}/.config/Jellyfin$" | awk '{print $1}') > /dev/null 2>&1
        rm_if_exists /opt/jellyfin
        rm_if_exists /opt/ffmpeg
        echo_progress_done "Old JF service removed"
    fi
    #
    # data migration to default locations.
    if [[ -d "/home/${username}/.config/Jellyfin/config" ]]; then
        echo_progress_start "Adjusting Jellyfin configs to new locations"
        mkdir -p /etc/jellyfin
        mkdir -p /var/lib/jellyfin/{data,root,metadata}
        #
        [[ -d "/home/${username}/.config/Jellyfin/config" ]] && cp -fRT "/home/${username}/.config/Jellyfin/config" /etc/jellyfin
        rm_if_exists /etc/jellyfin/encoding.xml
        [[ -d "/home/${username}/.config/Jellyfin/data" ]] && cp -fRT "/home/${username}/.config/Jellyfin/data" /var/lib/jellyfin/data
        [[ -f "/home/${username}/.config/Jellyfin/data/library.db" ]] && cp -f "/home/${username}/.config/Jellyfin/data/library.db" /var/lib/jellyfin/data/library.db.bak
        [[ -d "/home/${username}/.config/Jellyfin/metadata" ]] && cp -fRT "/home/${username}/.config/Jellyfin/metadata" /var/lib/jellyfin/metadata
        [[ -d "/home/${username}/.config/Jellyfin/root" ]] && cp -fRT "/home/${username}/.config/Jellyfin/root" /var/lib/jellyfin/root
        #
        sed -r 's#<PublicPort>(.*)</PublicPort>#<PublicPort>8096</PublicPort>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<PublicHttpsPort>(.*)</PublicHttpsPort>#<PublicHttpsPort>8920</PublicHttpsPort>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<HttpServerPortNumber>(.*)</HttpServerPortNumber>#<HttpServerPortNumber>8096</HttpServerPortNumber>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<HttpsPortNumber>(.*)</HttpsPortNumber>#<HttpsPortNumber>8920</HttpsPortNumber>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<RequireHttps>false</RequireHttps>#<RequireHttps>true</RequireHttps>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<CachePath>(.*)</CachePath>#<CachePath>/var/cache/jellyfin</CachePath>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<MetadataPath>(.*)</MetadataPath>#<MetadataPath>/var/lib/jellyfin/metadata</MetadataPath>#g' -i /etc/jellyfin/system.xml
        echo_warn "The Jellyfin ports have been moved to 8920 (SSL). Please update any applications that rely on the old random port"
        #
        if [[ -f /etc/nginx/apps/jellyfin.conf ]]; then
            sed -r 's#proxy_pass https://127.0.0.1:(.*);#proxy_pass https://127.0.0.1:8920;#g' -i /etc/nginx/apps/jellyfin.conf
            systemctl -q restart nginx.service
        fi
        #
        rm_if_exists "/home/${username}/.config/Jellyfin"
        rm_if_exists "/home/${username}/.cache/jellyfin"
        rm_if_exists "/home/${username}/.aspnet"
        #
        apt_update          # forces apt refresh
        apt_install sqlite3 # We need this to edit the library.db
        # Get our array of copied directories
        readarray -d '' jelly_array < <(find "/var/lib/jellyfin/root/default/" -maxdepth 1 -mindepth 1 -type d -print0)
        #
        for fixjelly in "${jelly_array[@]}"; do
            sqlite3 /var/lib/jellyfin/data/library.db "UPDATE TypedBaseItems SET Path=REPLACE(Path, \"/home/${username}/.config/Jellyfin/root/default/${fixjelly##*/}\", \"${fixjelly}\");"
            sqlite3 /var/lib/jellyfin/data/library.db "UPDATE TypedBaseItems SET Data=REPLACE(Data, \"/home/${username}/.config/Jellyfin/root/default/${fixjelly##*/}\", \"${fixjelly}\");"
        done
        echo_progress_done "Configs adjusted"
    fi
    #
    if ! check_installed jellyfin; then
        echo_progress_start "Moving Jellyfin to apt-managed installation"
        #
        # Add the jellyfin official repository and key to our installation so we can use apt-get to install it jellyfin and jellyfin-ffmepg.
        curl -s https://repo.jellyfin.org/$DIST_ID/jellyfin_team.gpg.key | gpg --dearmor > /usr/share/keyrings/jellyfin-archive-keyring.gpg 2>> "${log}"
        echo "deb [signed-by=/usr/share/keyrings/jellyfin-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/$DIST_ID $DIST_CODENAME main" > /etc/apt/sources.list.d/jellyfin.list
        #
        # install jellyfin and jellyfin-ffmepg using apt functions.
        apt_update #forces apt refresh
        apt_install jellyfin jellyfin-ffmpeg
        #
        # Configure the new jellyfin service.
        systemctl -q stop jellyfin.service
        #
        # Add the jellyfin user to the master user's group to use our ssl certs.
        usermod -a -G "${username}" jellyfin
        #
        # Set the correct and required permissions of any directories we created or modified.
        chown "${username}:${username}" -R "/home/${username}/.ssl"
        chmod -R g+r "/home/${username}/.ssl"
        #
        # Set the default permissions after we have migrated our data
        chown -R jellyfin:jellyfin "/etc/jellyfin"
        chown jellyfin:root "/etc/jellyfin/logging.json"
        chown jellyfin:adm "/etc/jellyfin"
        chown -R jellyfin:jellyfin "/var/lib/jellyfin"
        chown jellyfin:adm "/var/lib/jellyfin"
        #
        # Reload systemd and start the service.
        systemctl -q daemon-reload
        systemctl -q start jellyfin.service
        #
        echo_progress_done "Jellyfin updated"
    fi
fi

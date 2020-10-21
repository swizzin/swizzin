#!/usr/bin/env bash
#
if [[ -f /install/.jellyin.lock ]]; then
    #
    # source the functions we need for this script.
    . /etc/swizzin/sources/functions/utils
    #
    # Get our main user credentials using a util function.
    username="$(_get_master_username)"
    #
    # disable the service to make usre the mosrt up to date and correct service file is installed via apt.
    systemctl -q stop jellyfin.service
    #
    ## legacy start
    #
    # remove the old service and remove legacy files.
    if [[ -f /etc/systemd/system/jellyfin.service ]]; then
        systemctl -q disable --now jellyfin.service
        rm_if_exists /etc/systemd/system/jellyfin.service
        kill -9 $(ps xU ${username} | grep "/opt/jellyfin/jellyfin -d /home/${username}/.config/Jellyfin$" | awk '{print $1}') >/dev/null 2>&1
        rm_if_exists /opt/jellyfin
        rm_if_exists /opt/ffmpeg
    fi
    #
    # data migration to default locations.
    if [[ -d "/home/${username}/.config/Jellyfin/config" ]]; then
        mkdir -p /etc/jellyfin
        mkdir -p /var/lib/jellyfin/{data,root,metadata}
        #
        [[ -d "/home/${username}/.config/Jellyfin/config" ]] && cp -fRT "/home/${username}/.config/Jellyfin/config" /etc/jellyfin
        rm_if_exists /etc/jellyfin/encoding.xml
        [[ -d "/home/${username}/.config/Jellyfin/data" ]] && cp -fRT "/home/${username}/.config/Jellyfin/data" /var/lib/jellyfin/data
        [[ -d "/home/${username}/.config/Jellyfin/metadata" ]] && cp -fRT "/home/${username}/.config/Jellyfin/metadata" /var/lib/jellyfin/metadata
        [[ -d "/home/${username}/.config/Jellyfin/root" ]] && cp -fRT "/home/${username}/.config/Jellyfin/root" /var/lib/jellyfin/root
        #
        sed -r 's#<PublicPort>(.*)</PublicPort>#<PublicPort>8096</PublicPort>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<PublicHttpsPort>(.*)</PublicHttpsPort>#<PublicHttpsPort>8920</PublicHttpsPort>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<HttpServerPortNumber>(.*)</HttpServerPortNumber>#<HttpServerPortNumber>8096</HttpServerPortNumber>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<HttpsPortNumber>(.*)</HttpsPortNumber>#<HttpsPortNumber>8920</HttpsPortNumber>#g' -i /etc/jellyfin/system.xml
        sed -r 's#<RequireHttps>false</RequireHttps>#<RequireHttps>true</RequireHttps>#g' -i /etc/jellyfin/system.xml
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
        ## legacy end
        #
    fi
    #
    if ! check_installed jellyfin; then
        # Add the jellyfin official repository and key to our installation so we can use apt-get to install it jellyfin and jellyfin-ffmepg.
        wget -q -O - https://repo.jellyfin.org/debian/jellyfin_team.gpg.key | sudo apt-key add -
        echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/$(. /etc/os-release; echo $ID) $(lsb_release -cs) main" > /etc/apt/sources.list.d/jellyfin.list
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
        [[ -d "/home/${username}/.ssl" ]] && chown "${username}.${username}" -R "/home/${username}/.ssl"
        [[ -d "/home/${username}/.ssl" ]] && chmod -R g+r "/home/${username}/.ssl"
        #
        # Set the default permissions after we have migrated our data
        [[ -d "/etc/jellyfin" ]] && chown -R jellyfin:jellyfin "/etc/jellyfin"
        [[ -f "/etc/jellyfin/logging.json" ]] && chown jellyfin:root "/etc/jellyfin/logging.json"
        [[ -d "/etc/jellyfin" ]] && chown jellyfin:adm "/etc/jellyfin"
        [[ -d "/var/lib/jellyfin" ]] && chown -R jellyfin:jellyfin "/var/lib/jellyfin"
        [[ -d "/var/lib/jellyfin" ]] && chown jellyfin:adm "/var/lib/jellyfin"
        #
        # Reload systemd and start the service.
        systemctl -q daemon-reload
        systemctl -q start jellyfin.service
        #
        echo -e "\nJellyfin upgrade completed and service restarted\n"
    fi
fi

#!/usr/bin/env bash
#
if [[ -f /install/.jellyfin.lock ]]; then
    # source the functions we need for this script.
    #shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    # Get our main user credentials using a util function.
    username="$(_get_master_username)"
    #
    # remove the old service and remove legacy files.
    if [[ -f /etc/systemd/system/jellyfin.service ]]; then
        echo_progress_start "Removing old Jellyfin service"
        systemctl stop jellyfin.service
        systemctl -q disable --now jellyfin.service
        rm_if_exists /etc/systemd/system/jellyfin.service
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
        echo_progress_done "Configs adjusted"
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
    fi
    #
    if ! check_installed jellyfin; then
        echo_info "Updating Jellyfin installation using apt."
        #
        # Make sure universe is enabled so that ffmpeg can be satisfied.
        sudo add-apt-repository universe

        # Handle some known alternative base OS values with 1-to-1 mappings
        # Use the result as the repository base OS
        ARCHITECTURE="$(dpkg --print-architecture)"
        BASE_OS="$(awk -F'=' '/^ID=/{ print $NF }' /etc/os-release)"
        case "${BASE_OS}" in
            raspbian)
                # Raspbian uses the Debian repository
                REPO_OS="debian"
                ;;
            linuxmint)
                # Linux Mint can either be Debian- or Ubuntu-based, so pick the right one
                if grep -q "DEBIAN_CODENAME=" /etc/os-release &> /dev/null; then
                    VERSION="$(awk -F'=' '/^DEBIAN_CODENAME=/{ print $NF }' /etc/os-release)"
                    REPO_OS="debian"
                else
                    VERSION="$(awk -F'=' '/^UBUNTU_CODENAME=/{ print $NF }' /etc/os-release)"
                    REPO_OS="ubuntu"
                fi
                ;;
            neon)
                # Neon uses the Ubuntu repository
                REPO_OS="ubuntu"
                ;;
            *)
                REPO_OS="${BASE_OS}"
                VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
                ;;
        esac

        #
        # Check if old, outdated repository for jellyfin is installed
        # If old repository is found, delete it.
        if [[ -f /etc/apt/sources.list.d/jellyfin.list ]]; then
            echo_progress_start "Found old-style '/etc/apt/sources.list.d/jellyfin.list' configuration; removing it."
            rm -f /etc/apt/sources.list.d/jellyfin.list
            rm -f /etc/apt/keyrings/jellyfin.gpg
            echo_progress_done "Removed old repository."
        fi

        #
        # Add Jellyfin signing key if not already present
        if [[ ! -f /etc/apt/keyrings/jellyfin.gpg ]]; then
            echo_progress_start "> Did not find signing key. Adding it."
            curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor --yes --output /etc/apt/keyrings/jellyfin.gpg
            echo_progress_done "Jellyfin Signing Key Added"
        fi

        #
        # Install the Deb822 format jellyfin.sources entry
        echo_progress_start "Adding Jellyfin repository to apt"
        cat << EOF | tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${REPO_OS}
Suites: ${VERSION}
Components: main
Architectures: ${ARCHITECTURE}
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
        echo_progress_done "Added Jellyfin repository"
        #
        # Update apt repositories to fetch Jellyfin repository
        apt_update #forces apt refresh

        #
        # Install Jellyfin and dependencies using apt
        # Dependencies are automatically grabbed by apt
        apt_install jellyfin

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
        echo_success "Jellyfin updated"
    fi
fi

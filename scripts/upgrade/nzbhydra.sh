#!/bin/bash

. /etc/swizzin/sources/functions/utils
active=$(systemctl is-active nzbhydra)
username=$(_get_master_username)

if [[ -d /opt/.venv/nzbhydra ]]; then
    echo_query "NZBHydra v1 detected. Do you want to migrate data?\nIf you select no, a migration will not be attempted but your old data will be left." ""
    select yn in "Yes" "No"; do
        case $yn in
            Yes)
                migrate=True
                majorupgrade=True
                break
                ;;
            No)
                migrate=False
                majorupgrade=True
                break
                ;;
        esac
    done
    if [[ $migrate == True ]]; then
        echo_query "Do you wish to migrate your old database? If you select no, only settings will be transferred." ""
        select yn in "Yes" "No"; do
            case $yn in
                Yes)
                    database=true
                    break
                    ;;
                No)
                    database=false
                    break
                    ;;
            esac
        done
        oldport=$(grep \"port\" /home/${username}/.config/nzbhydra/settings.cfg | grep -oP '\d+')
        oldbase=$(grep \"urlBase\" /home/${username}/.config/nzbhydra/settings.cfg | cut -d\" -f4)
        oldbaseconv=$(echo $oldbase | sed 's|/|%2F|g')
        if [[ ! $active == "active" ]]; then
            systemctl start nzbhydra
            sleep 5
            if ! systemctl is-active nzbhydra; then
                echo_error "NZBHydra must be running in order to be migrated!"
                exit 1
            fi
        fi
    fi
fi

#ip=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

LIST='default-jre-headless unzip jq'
apt_install $LIST

if ! dpkg -s jq > /dev/null 2>&1; then
    echo_error "jq did not get installed. This is likely an error which will go away if you rerun this function."
    exit 1
fi

if [[ $migrate == True ]]; then
    version="2.10.2"
    cd /opt
    mkdir nzbhydra2
    cd nzbhydra2
    wget -O nzbhydra2.zip https://github.com/theotherp/nzbhydra2/releases/download/v${version}/nzbhydra2-${version}-linux.zip >> ${log} 2>&1
    unzip nzbhydra2.zip >> ${log} 2>&1
    chmod +x nzbhydra2
    rm -f nzbhydra2.zip
    chown -R ${username}: /opt/nzbhydra2
    echo_progress_start "Initializing NZBHydra2"
    sudo -u ${username} bash -c "cd /opt/nzbhydra2; /opt/nzbhydra2/nzbhydra2 --daemon --nobrowser --datafolder /home/${username}/.config/nzbhydra2 --nopidfile > /dev/null 2>&1"
    #if [[ -f /install/.nginx.lock ]]; then
    #    message="Go to nzbhydra2 (http://${ip}:5076) and follow the migration instructions. When prompted, your old NZBHydra install should be located at http://127.0.0.1:5075/nzbhydra. Press enter once migration is complete."
    #else
    #    message="Go to nzbhydra2 (http://${ip}:5076) and follow the migration instructions. When prompted, your old NZBHydra install should be located at http://127.0.0.1:5075. Press enter once migration is complete."
    #    message=$(curl "http://127.0.0.1:5076/internalapi/migration/url?baseurl=http:%2F%2F127.0.0.1:5075&doMigrateDatabase=true")
    #fi
    sleep 15
    echo_progress_done "NZBhydra2 initialised"

    echo_progress_start "Starting migration"
    result=$(curl -s "http://127.0.0.1:5076/internalapi/migration/url?baseurl=http:%2F%2F127.0.0.1:${oldport}${oldbaseconv}&doMigrateDatabase=${database}")
    errors=$(echo $result | jq .error)
    if [[ $errors == null ]]; then
        echo_info "  configMigrated: $(echo $result | jq .configMigrated)"
        if [[ $database == true ]]; then
            echo_info "  databaseMigrated: $(echo $result | jq .databaseMigrated)"
        fi

        echo_progress_done "No errors reported!"
        #shellcheck disable=SC2162
        echo_query "Press enter to continue setting up NZBHydra2"
        read
    else
        echo_error "Something appears to have gone wrong during the migration. Upgrader will now exit.
Error: $errors"
        cd /opt
        rm -rf nzbhydra2
        rm -rf /home/${username}/.config/nzbhydra2
        killall nzbhydra2 >> ${log} 2>&1
        exit 1
    fi

    killall nzbhydra2 >> ${log} 2>&1
    sleep 10
    echo_progress_done "Migration complete"
    echo_query "Press enter to continue setting up NZBHydra2" "enter"
    read
fi

if [[ $majorupgrade == True ]]; then
    echo_progress_start "Re-configuring system for NZBHydra2"
    systemctl stop nzbhydra
    rm_if_exists /etc/nginx/apps/nzbhydra.conf
    rm_if_exists /opt/.venv/nzbhydra
    rm_if_exists /opt/nzbhydra
    cat > /etc/systemd/system/nzbhydra.service << EOH2
[Unit]
Description=NZBHydra2 Daemon
Documentation=https://github.com/theotherp/nzbhydra2
After=network.target

[Service]
User=${username}
Type=simple
# Set to the folder where you extracted the ZIP
WorkingDirectory=/opt/nzbhydra2


# NZBHydra stores its data in a "data" subfolder of its installation path
# To change that set the --datafolder parameter:
# --datafolder /path-to/datafolder
ExecStart=/opt/nzbhydra2/nzbhydra2wrapperPy3.py --nobrowser --datafolder /home/${username}/.config/nzbhydra2 --nopidfile

Restart=always

[Install]
WantedBy=multi-user.target
EOH2
    systemctl daemon-reload
    if [[ -f /install/.nginx.lock ]]; then
        bash /etc/swizzin/scripts/nginx/nzbhydra.sh
        systemctl reload nginx
    fi
    echo_progress_done "Systemd files reconfigured"
fi

localversion=$(/opt/nzbhydra2/nzbhydra2 --version 2> /dev/null | grep -oP 'v\d+\.\d+\.\d+')
latest=$(curl -s https://api.github.com/repos/theotherp/nzbhydra2/releases/latest | grep -E "browser_download_url" | grep linux | head -1 | cut -d\" -f 4)
latestversion=$(echo $latest | grep -oP 'v\d+\.\d+\.\d+')
if [[ -z $localversion ]] || dpkg --compare-versions ${localversion#v} lt ${latestversion#v}; then
    echo_progress_start "Upgrading NZBHydra to ${latestversion}"
    cd /opt
    rm_if_exists /opt/nzbhydra2
    mkdir nzbhydra2
    cd nzbhydra2
    wget -O nzbhydra2.zip ${latest} >> ${log} 2>&1
    unzip nzbhydra2.zip >> ${log} 2>&1
    rm -f nzbhydra2.zip

    chmod +x nzbhydra2 nzbhydra2wrapperPy3.py
    chown -R ${username}: /opt/nzbhydra2

    if [[ $active == "active" ]]; then
        systemctl restart nzbhydra
    fi
    echo_progress_done "Installed"
else
    echo_error "Installed version (${localversion}) matches latest version (${latestversion})."
    exit 1
fi

if [[ $majorupgrade == True ]]; then
    echo_info "NZBHydra v1 config files have been left at /home/${username}/.config/nzbhydra. Please remove them if they are no longer needed."
fi

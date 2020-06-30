#!/bin/bash
# Sonarr v3 installer
# Flying sauasges for swizzin 2020

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

#Handles existing v2 instances
_sonarrv2_flow(){

    v2present=false
    if [[ -f /install/.sonarr.lock ]]; then 
        v2present=true
    fi
    if dpkg -l | grep nzbdrone > /dev/null 2>&1 ; then 
        v2present=true
    fi

    if [[ $v2present == "true" ]]; then 
        echo "Sonarr v2 is detected. Continuing will upgrade your current installation." | tee -a $log
        echo "You can read more about the v2->v3 migration at https://docs.swizzin.ltd/applications/sonarrv3#migrating-from-v2"
        echo "An additional copy of the backup will be made into /root/sonarrv2.bak/" | tee -a $log
        #shellcheck source=sources/functions/ask
        . /etc/swizzin/sources/functions/ask

        if ! ask "Do you want to continue?" N; then
            exit 0
        fi

        # TODO make backup
        # TODO 
        echo "Backing up Sonarr v2" | tee -a $log

        address="http://localhost:8989/sonarr/api"
        master=$(cut -d: -f1 < /root/.master.info)
        apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"${master}"/.config/NzbDrone/config.xml)

        #This starts a backup on the current Sonarr instance. The logic below waits until the query returns as "completed"
        id=$(curl -sd '{name: "backup"}' -H "Content-Type: application/json" -X POST ${address}/command?apikey="${apikey}" | jq '.id' )
        
        if [[ -z $id ]]; then 
            echo "Sonarr is not reachable." | tee -a $log
            echo "We cannot trigger Sonarr to dump a current backup, but the current files and previous weekly backups can still be copied" | tee -a $log
            if ! ask "Continue without triggering internal Sonarr backup?" N; then 
                exit 1
            fi
        else
            echo "Sonarr backup Job ID = $id, waiting to finish" >> $log

            status=""
            while [[ $status != "\"completed\"" ]]; do 
                status=$(curl -s "${address}/command/$id?apikey=${apikey}" | jq '.status')
                sleep 0.1
            done
            echo "Sonarr backup completed" >> $log
        fi

        cp -R /home/"${master}"/.config/NzbDrone /root/sonarrv2.bak
        
        systemctl stop sonarr@"${master}" 

        # We don't have the debconf configuration yet so we can't migrate the data.
        # Instead we symlink so postinst knows where it's at.
        if [ -f "/usr/lib/sonarr/nzbdrone-appdata" ]; then
            rm "/usr/lib/sonarr/nzbdrone-appdata"
        else
            mkdir -p "/usr/lib/sonarr"
        fi
        ln -s /home/"${master}"/.config/NzbDrone /usr/lib/sonarr/nzbdrone-appdata
        # chown -R "$master":"$master" /usr/lib/sonarr/nzbdrone-appdata
        
        echo "Removing Sonarr v2" | tee -a $log
        # shellcheck source=scripts/remove/sonarr.sh 
        bash /etc/swizzin/scripts/remove/sonarr.sh
    fi
}

_setup_apt_sonarrv3 () {
    echo "Adding apt sources for Sonarr v3" | tee -a $log
    codename=$(lsb_release -cs)
    distribution=$(lsb_release -is)

    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8 >> $log 2>&1
    echo "deb https://apt.sonarr.tv/${distribution,,} ${codename,,} main" | tee /etc/apt/sources.list.d/sonarr.list >> $log 2>&1

    #shellcheck source=sources/functions/mono
    . /etc/swizzin/sources/functions/mono
    mono_repo_setup

    apt-get update >> $log 2>&1

    if ! apt policy sonarr | grep apt.sonarr.tv; then
        echo "Sonarr was not found from apt.sonarr.tv repository. Please inspect the logs and try again later."
        exit 1
    fi

}

_install_sonarrv3 () {
    echo "Installing Sonarr v3 from apt" | tee -a $log
    # settings relevant from https://github.com/Sonarr/Sonarr/blob/phantom-develop/distribution/debian/config
    master=$(cut -d: -f1 < /root/.master.info)
    echo "sonarr sonarr/owning_user  string ${master}" | debconf-set-selections
    echo "sonarr sonarr/owning_group string ${master}" | debconf-set-selections
    DEBIAN_FRONTEND=non-interactive apt-get install -y sonarr >> $log 2>&1
    if [[ $? -gt 0 ]];              then failure=true; fi
    if [[ ! -d /var/lib/sonarr ]];  then failure=true; fi

    if [[ $failure = "true" ]]; then
        echo "ERROR: The Sonarr v3 pacakge did not install correctly. Please try again. (Is sonarr repo reachable?)"
        exit 1
    fi
}

_nginx_sonarr () {
    sleep 20
    echo "Installing nginx configuration" | tee -a $log
    if [[ -f /install/.nginx.lock ]]; then
        bash /usr/local/bin/swizzin/nginx/sonarrv3.sh
        systemctl reload nginx >> $log 2>&1
    fi
}

_sonarrv2_flow
_setup_apt_sonarrv3
_install_sonarrv3
_nginx_sonarr

touch /install/.sonarrv3.lock

if [[ -f /install/.ombi.lock ]]; then
    echo "Please adjust your Ombi setup accordingly"
fi
if [[ -f /install/.bazarr.lock ]]; then
    echo "Please adjust your Bazarr setup accordingly"
fi
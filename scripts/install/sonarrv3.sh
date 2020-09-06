#!/bin/bash
# Sonarr v3 installer
# Flying sauasges for swizzin 2020

if [[ -f /tmp/.install.lock ]]; then
  export log="/root/logs/install.log"
else
  log="/root/logs/swizzin.log"
fi

#shellcheck source=sources/functions/ask
. /etc/swizzin/sources/functions/ask

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
        echo "Sonarr v2 is detected."
        echo "Continuing will migrate your current v2 installation." | tee -a $log
        echo "You can read more about the migration at https://docs.swizzin.ltd/applications/sonarrv3#migrating-from-v2"
        echo "An additional copy of the backup will be made into /root/sonarrv2.bak/" | tee -a $log
        if ! ask "Do you want to continue?" N; then
            exit 0
        fi

        if ask "Would you like to trigger a Sonarr-side backup?" Y; then 
            echo "Backing up Sonarr v2" | tee -a $log
            if [[ -f /install/.nginx ]]; then 
                address="http://127.0.0.1:8989/sonarr/api"
            else
                address="http://127.0.0.1:8989/api"
            fi

            [[ -z $sonarrv2owner ]] && sonarrv2owner=$(cut -d: -f1 < /root/.master.info) && export sonarrv2owner
            if [[ ! -d /home/"${sonarrv2owner}"/.config/NzbDrone ]]; then
                echo "No Sonarr config folder found for $sonarrv2owner. Exiting" | tee -a $log
                exit 1
            fi

            apikey=$(awk -F '[<>]' '/ApiKey/{print $3}' /home/"${sonarrv2owner}"/.config/NzbDrone/config.xml)
            echo "apikey = $apikey" >> $log

            #This starts a backup on the current Sonarr instance. The logic below waits until the query returns as "completed"
            response=$(curl -sd '{name: "backup"}' -H "Content-Type: application/json" -X POST ${address}/command?apikey="${apikey}")
            echo "$response" >> $log
            id=$(echo "$response" | jq '.id' )
            echo "id=$id" >> $log

            if [[ -z $id ]]; then 
                echo "Failure triggering backup (see logs)." | tee -a $log
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
        fi

        cp -R /home/"${sonarrv2owner}"/.config/NzbDrone /root/sonarrv2.bak
        
        systemctl stop sonarr@"${sonarrv2owner}" 

        # We don't have the debconf configuration yet so we can't migrate the data.
        # Instead we symlink so postinst knows where it's at.
        if [ -f "/usr/lib/sonarr/nzbdrone-appdata" ]; then
            rm "/usr/lib/sonarr/nzbdrone-appdata"
        else
            mkdir -p "/usr/lib/sonarr"
        fi
        ln -s /home/"${sonarrv2owner}"/.config/NzbDrone /usr/lib/sonarr/nzbdrone-appdata
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

    if ! apt-cache policy sonarr | grep apt.sonarr.tv > /dev/null; then
        echo "Sonarr was not found from apt.sonarr.tv repository. Please inspect the logs and try again later."
        exit 1
    fi

}

_install_sonarrv3 () {
    echo "Installing Sonarr v3 from apt" | tee -a $log
    # settings relevant from https://github.com/Sonarr/Sonarr/blob/phantom-develop/distribution/debian/config
    # [[ -z $sonarrv3owner ]] && export sonarrv3owner=$(cut -d: -f1 < /root/.master.info)
    # echo "sonarr sonarr/owning_user  string ${sonarrv3owner}" | debconf-set-selections
    # echo "sonarr sonarr/owning_group string ${sonarrv3owner}" | debconf-set-selections
    DEBIAN_FRONTEND=non-interactive apt-get install -y sonarr >> $log 2>&1
    #shellcheck disable=SC2181
    if [[ $? -gt 0 ]];              then failure=true; fi
    if [[ ! -d /var/lib/sonarr ]];  then failure=true; fi

    if [[ $failure = "true" ]]; then
        echo "ERROR: The Sonarr v3 pacakge did not install correctly. Please try again. (Is sonarr repo reachable?)"
        exit 1
    fi
}

_add2usergroups_sonarrv3 () {
    echo "Adding Sonarr to master user's group" | tee -a $log
    # shellcheck source=sources/functions/utils
    . /etc/swizzin/sources/functions/utils
    master=$(_get_master_username)
    usermod -a -G "$master" sonarr
    chmod g+rwx /home/"$master"

    if [[ -n $sonarrv2owner ]]; then
        usermod -a -G "$sonarrv2owner" sonarr
        chmod g+rwx /home/"$sonarrv2owner"
    fi

    if ask "Do you want to let Sonarr access other users' home directories?" N; then
        echo "Space separated list of users to give sonarr access to: (e.g. \"user1 user2\")"
        read -r grouplist
        for u in $grouplist; do
            usermod -a -G "$u" sonarr | tee -a $log
            chmod g+rwx /home/"$u"
        done
    fi
}

_nginx_sonarr () {
    #TODO what is this sleep here for? See if this can be fixed by doing a check for whatever it needs to
    if [[ -f /install/.nginx.lock ]]; then
        sleep 20
        echo "Installing nginx configuration" | tee -a $log
        bash /usr/local/bin/swizzin/nginx/sonarrv3.sh
        systemctl reload nginx >> $log 2>&1
    fi
}

_sonarrv2_flow
_setup_apt_sonarrv3
_install_sonarrv3
_add2usergroups_sonarrv3
_nginx_sonarr

touch /install/.sonarrv3.lock

if [[ -f /install/.ombi.lock ]]; then
    echo "Please adjust your Ombi setup accordingly"
fi

if [[ -f /install/.bazarr.lock ]]; then
    echo "Please adjust your Bazarr setup accordingly"
fi
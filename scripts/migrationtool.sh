#!/usr/bin/env bash
# Yo this is all seriously untested
#shellcheck disable=SC2086

#Migration utility

if [[ $EUID -ne 0 ]]; then
    echo "You gotta run this as root yo"
    exit 1
fi

#shellcheck source=sources/globals.sh
. /etc/swizzin/sources/functions/users
echo_log_only ">>>> \`box $*\`"
echo_log_only "git @ $(git --git-dir=/etc/swizzin/.git rev-parse --short HEAD) 2>&1"

# Check server connection
target="$1"
ssh -t "$target" || {
    echo_error "Could not connect to target. Please set up in your config"
    exit 1
}

ssh root@$target -c

# Get list of apps
apps=$(ssh root@$target -C "
    
    
")

# Switch off all apps on target and prepare them
for a in "${apps[@]}"; do
    case "${a}" in
        transmission | deluge | rtorrent | qbittorrent)
            #Multiuser apps
            ssh root@$target -C "
                . /etc/swizzin/sources/functions/users
                readarray -t users < <(_get_user_list)
                for user in \"\${users[@]}\"; do
                    systemctl disable --now $a@\"\$user\"
                done
            "
            ;;
        rutorrent | nextcloud | organizr | librespeed | quota | ffmpeg)
            : #do nothing, no service
            ;;
        wireguard)
            : # do nothing, could be in use. move configs so that they don't conflict
            ssh root@$target -C "
                . /etc/swizzin/sources/functions/users
                readarray -t users < <(_get_user_list)
                for user in \"\${users[@]}\"; do
                    mv /home/\$user/.wireguard /home/\$user/.wireguard-old-server
                done
            "
            ;;
        # the ones below here are just different names to the packges
        sonarrv3)
            ssh root@$target -C "systemctl disable --now sonarr"
            ;;
        plex)
            ssh root@$target -C "systemctl disable --now plexmediaserver"
            ;;
        # default case
        *)
            ssh root@$target -C "systemctl disable --now $a" || {
                echo "something went wrong, chance is we do not support migrating $a yet or the SSH connection could not be established"
            }
            ;;
    esac
done

# Get list of users on target
normal_users=$(ssh root@$target -C "
    . /etc/swizzin/sources/functions/users
    _get_user_list | grep -v $(_get_master_username)
")

#Creates a user and starts their data transfer
migrate_user() {
    user="$1"
    pass=$(ssh root@$target -C "
    . /etc/swizzin/sources/functions/users
    _get_user_password $user
    ")
    echo "user = $user; pass = $pass"
    if [ "$user" = "$(get_master_username)" ]; then
        echo "This user seems to be the master user."
    else
        box adduser "$user" "$pass"
    fi
    systemctl disable --now transmission@"$user"
    systemctl disable --now rtorrent@"$user"
    systemctl disable --now deluge@"$user"
    systemctl disable --now qbittorrent@"$user"
    echo "Starting background sync for $user, resume services afterwards yourself"
    screen -S swizzinmigration-"$user" -dm bash -c "rsync -ahH --stats -e \"ssh -p 22722\" root@ssg.land:/home/$user/ /home/$user --info=progress2 --usermap=$user:$user; read"
}

for u in "${normal_users[@]}"; do
    migrate_user "$u"
done

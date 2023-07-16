#!/bin/bash

if [ -f /install/.rutorrent.lock ]; then
    #Update club-QuickBox with latest changes
    if [[ -d /srv/rutorrent/plugins/theme/themes/club-QuickBox ]]; then
        find /srv/rutorrent/plugins/theme/themes/club-QuickBox -user root -exec chown www-data: {} \;
        cqbdir="/srv/rutorrent/plugins/theme/themes/club-QuickBox"
        sudo -u www-data git -C "$cqbdir" fetch
        if [[ ! $(sudo -u www-data git -C "$cqbdir" rev-parse HEAD) == $(sudo -u www-data git -C "$cqbdir" rev-parse @{u}) ]]; then
            echo_progress_start "Updating rutorrent theme"
            sudo -u www-data git -C "$cqbdir" reset HEAD --hard >> $log 2>&1
            sudo -u www-data git -C "$cqbdir" pull >> $log 2>&1
            echo_progress_done
        fi
    fi

    reloadnginx=0

    if [[ -f /etc/nginx/apps/rutorrent.conf ]]; then
        #Fix fastcgi path_info being blank with certain circumstances under ruTorrent
        #Essentially, disabling the distro snippet and ignoring try_files
        if grep -q '/srv\$fastcgi_script_name' /etc/nginx/apps/rutorrent.conf; then
            sed -i 's|/srv$fastcgi_script_name|$request_filename|g' /etc/nginx/apps/rutorrent.conf
            echo_log_only "ruTorrent fastcgi_script_name triggers nginx reload"
            reloadnginx=1
        fi
        if grep -q 'alias' /etc/nginx/apps/rutorrent.conf; then
            sed -i '/alias/d' /etc/nginx/apps/rutorrent.conf
            echo_log_only "ruTorrent alias triggers nginx reload"
            reloadnginx=1
        fi
        if ! grep -q fastcgi_split_path_info /etc/nginx/apps/rutorrent.conf; then
            sed -i 's|include snippets/fastcgi-php.conf;|fastcgi_split_path_info ^(.+\\.php)(/.+)$;|g' /etc/nginx/apps/rutorrent.conf
            sed -i '/SCRIPT_FILENAME/a \ \ \ \ include fastcgi_params;\n    fastcgi_index index.php;' /etc/nginx/apps/rutorrent.conf
            echo_log_only "ruTorrent fastcgi_split_path_info triggers nginx reload"
            reloadnginx=1
        fi
    fi

    if [[ -f /install/.flood.lock ]]; then
        users=($(cut -d: -f1 < /etc/htpasswd))
        for user in ${users[@]}; do
            if [[ ! -f /etc/nginx/apps/${user}.scgi.conf ]]; then
                reloadnginx=1
                cat > /etc/nginx/apps/${user}.scgi.conf << RUC
location /${user} {
    include scgi_params;
    scgi_pass unix:/var/run/${user}/.rtorrent.sock;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
RUC
            fi
        done
    fi

    if [[ $reloadnginx == 1 ]]; then
        echo_progress_start "Reloading nginx due to ruTorrent config updates"
        systemctl reload nginx
        echo_progress_done
    fi

    if [[ -f /install/.quota.lock ]] && { ! grep -q "/usr/bin/quota -wu" /srv/rutorrent/plugins/diskspace/action.php > /dev/null 2>&1 || [[ ! $(grep -ic cachedEcho::send /srv/rutorrent/plugins/diskspace/action.php) == 2 ]]; }; then
        echo_progress_start "Fixing quota ruTorrent plugin"
        . /etc/swizzin/sources/functions/rutorrent
        rutorrent_fix_quota
        . /etc/swizzin/sources/functions/php
        restart_php_fpm
        echo_progress_done
    fi

fi

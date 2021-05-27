#!/bin/bash

if [ -f /install/.rutorrent.lock ]; then
    #Update club-QuickBox with latest changes
    if [[ -d /srv/rutorrent/plugins/theme/themes/club-QuickBox ]]; then
        cqbdir="/srv/rutorrent/plugins/theme/themes/club-QuickBox"
        git -C "$cqbdir" fetch
        if [[ ! $(git -C "$cqbdir" rev-parse HEAD) == $(git -C "$cqbdir" rev-parse @{u}) ]]; then
            echo_progress_start "Updating rutorrent theme"
            git -C "$cqbdir" reset HEAD --hard >> $log 2>&1
            git -C "$cqbdir" pull >> $log 2>&1
            echo_progress_done
        fi
    fi

    if [[ -d /srv/rutorrent/plugins/theme/themes/DarkBetter ]]; then
        if [[ -z "$(ls -A /srv/rutorrent/plugins/theme/themes/DarkBetter/)" ]]; then
            echo_progress_start "Updating rutorrent submodules"
            git submodule update --init --recursive -C /srv/rutorrent >> $log 2>&1
            echo_progress_done
        fi

    fi

    reloadnginx=0

    if [[ -f /etc/nginx/apps/rutorrent.conf ]]; then
        #Fix fastcgi path_info being blank with certain circumstances under ruTorrent
        #Essentially, disabling the distro snippet and ignoring try_files
        if grep -q '/srv\$fastcgi_script_name' /etc/nginx/apps/rutorrent.conf; then
            sed -i 's|/srv$fastcgi_script_name|$request_filename|g' /etc/nginx/apps/rutorrent.conf
            echo_log_only "rutorrent fastcgi_script_name triggers nginx reload"
            reloadnginx=1
        fi
        if grep -q 'alias' /etc/nginx/apps/rutorrent.conf; then
            sed -i '/alias/d' /etc/nginx/apps/rutorrent.conf
            echo_log_only "rutorrent alias triggers nginx reload"
            reloadnginx=1
        fi
        if ! grep -q fastcgi_split_path_info /etc/nginx/apps/rutorrent.conf; then
            sed -i 's|include snippets/fastcgi-php.conf;|fastcgi_split_path_info ^(.+\\.php)(/.+)$;|g' /etc/nginx/apps/rutorrent.conf
            sed -i '/SCRIPT_FILENAME/a \ \ \ \ include fastcgi_params;\n    fastcgi_index index.php;' /etc/nginx/apps/rutorrent.conf
            echo_log_only "rutorrent fastcgi_split_path_info triggers nginx reload"
            reloadnginx=1
        fi
    fi

    if [[ -f /install/.flood.lock ]]; then
        users=($(cut -d: -f1 < /etc/htpasswd))
        for u in ${users[@]}; do
            if [[ ! -f /etc/nginx/apps/${u}.scgi.conf ]]; then
                reloadnginx=1
                cat > /etc/nginx/apps/${u}.scgi.conf << RUC
location /${u} {
include scgi_params;
scgi_pass unix:/var/run/${u}/.rtorrent.sock;
auth_basic "What's the password?";
auth_basic_user_file /etc/htpasswd.d/htpasswd.${u};
}
RUC
            fi
        done
    fi

    if [[ $reloadnginx == 1 ]]; then
        echo_progress_start "Reloading nginx due to rutorrent config updates"
        systemctl reload nginx
        echo_progress_done
    fi

    if [[ -f /install/.quota.lock ]] && { ! grep -q "/usr/bin/quota -wu" /srv/rutorrent/plugins/diskspace/action.php > /dev/null 2>&1 || [[ ! $(grep -c cachedEcho /srv/rutorrent/plugins/diskspace/action.php) == 2 ]]; }; then
        echo_progress_start "Fixing quota rutorrent plugin"
        cat > /srv/rutorrent/plugins/diskspace/action.php << 'DSKSP'
<?php
#################################################################################
##  [Quick Box - action.php modified for quota systems use]
#################################################################################
# QUICKLAB REPOS
# QuickLab _ packages:   https://github.com/QuickBox/quickbox_rutorrent-plugins
# LOCAL REPOS
# Local _ packages   :   ~/QuickBox/rtplugins
# Author             :   QuickBox.IO
# URL                :   https://plaza.quickbox.io
#
#################################################################################
  require_once( '../../php/util.php' );
  if (isset($quotaUser) && file_exists('/install/.quota.lock')) {
    $total = shell_exec("sudo /usr/bin/quota -wu ".$quotaUser."| tail -n 1 | sed -e 's|^[ \t]*||' | awk '{print $3*1024}'");
    $used = shell_exec("sudo /usr/bin/quota -wu ".$quotaUser."| tail -n 1 | sed -e 's|^[ \t]*||' | awk '{print $2*1024}'");
    $free = sprintf($total - $used);
    cachedEcho('{ "total": '.$total.', "free": '.$free.' }',"application/json");
  } else {
      cachedEcho('{ "total": '.disk_total_space($topDirectory).', "free": '.disk_free_space($topDirectory).' }',"application/json");
  }
?>
DSKSP
        . /etc/swizzin/sources/functions/php
        restart_php_fpm
        echo_progress_done
    fi

fi

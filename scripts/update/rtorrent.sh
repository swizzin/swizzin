#!/bin/bash
users=($(cut -d: -f1 < /etc/htpasswd))

for u in "${users[@]}"; do
    # Create tmpfiles.d for user if not exists
    if [[ ! -f /etc/tmpfiles.d/${u}.conf ]]; then
        echo_progress_start "Creating rtorrent tmpfiles.d for ${u}"
        echo "D /var/run/${u} 0750 ${u} ${u} -" >> /etc/tmpfiles.d/${u}.conf
        systemd-tmpfiles /etc/tmpfiles.d/${u}.conf --create
        echo_progress_done
    fi

    if [[ -f /home/${u}/.rtorrent.rc ]]; then
        if grep -q network.scgi.open_local /home/${u}/.rtorrent.rc; then
            :
        else
            sed -i 's/network.scgi.open_port.*/network.scgi.open_local = \/var\/run\/'${u}'\/.rtorrent.sock\nschedule2 = chmod_scgi_socket, 0, 0, "execute2=chmod,\\"g+w,o=\\",\/var\/run\/'${u}'\/.rtorrent.sock"/' /home/${u}/.rtorrent.rc
            restart=1
        fi
        if ! grep -q /srv/rutorrent/php/initplugins.php /home/${u}/.rtorrent.rc; then
            sed -i 's:/var/www/rutorrent/php/initplugins.php:/srv/rutorrent/php/initplugins.php:g' /home/${u}/.rtorrent.rc
            restart=1
        fi
    fi
    if [[ $restart = 1 ]]; then
        echo_progress_start "Restarting rtorrent for ${u} after config update"
        systemctl try-restart rtorrent@${u}
        echo_progress_done
    fi
    # Check if rTorrent using outdated/insecure scgi bind
    if [[ -f /etc/nginx/apps/${u}.scgi.conf ]]; then
        if grep -q "scgi_pass 127.0.0.1" /etc/nginx/apps/${u}.scgi.conf; then
            echo_progress_start "Updating nginx scgi config for ${u}"
            sed -i 's/scgi_pass.*/scgi_pass unix:\/var\/run\/'${u}'\/.rtorrent.sock;/g' /etc/nginx/apps/${u}.scgi.conf
            systemctl reload nginx
            echo_progress_done
        fi
    fi
    if [[ -f /srv/rutorrent/conf/users/${u}/config.php ]]; then
        if grep -q "scgi_host" /srv/rutorrent/conf/users/${u}/config.php; then
            :
        else
            echo_progress_start "Updating rutorrent config.php to use sockets for ${u}"
            sed -i 's/$scgi_port.*/$scgi_port = 0;\n$scgi_host = "unix:\/\/\/var\/run\/'${u}'\/.rtorrent.sock";/g' /srv/rutorrent/conf/users/${u}/config.php
            /usr/local/bin/swizzin/php-fpm-cli -r 'opcache_reset();'
            echo_progress_done
        fi
    fi
    if [[ -f /home/${u}/.flood/config.js ]]; then
        if grep -q "socket: false" /home/${u}/.flood/config.js; then
            echo_progress_start "Updating flood config.js to use sockets for ${u}"
            sed -i "s/socket: false/socket: true/g" /home/${u}/.flood/config.js
            sed -i "s/socketPath.*/socketPath: '\/var\/run\/${u}\/.rtorrent.sock'/g" /home/${u}/.flood/config.js
            systemctl try-restart flood@${u}
            echo_progress_done
        fi
    fi
done

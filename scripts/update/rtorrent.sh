#!/bin/bash

if [ -f /install/.rtorrent.lock ]; then

    users=($(cut -d: -f1 < /etc/htpasswd))
    for u in "${users[@]}"; do
        if [[ ! -f /etc/tmpfiles.d/${u}.conf ]]; then
            echo_log_only "fixing tmpfiles for $u"
            echo "D /var/run/${u} 0750 ${u} ${u} -" >> /etc/tmpfiles.d/${u}.conf
            systemd-tmpfiles /etc/tmpfiles.d/${u}.conf --create
        fi
        if [[ -f /home/${u}/.rtorrent.rc ]]; then
            if grep -q network.scgi.open_local /home/${u}/.rtorrent.rc; then
                :
            else
                echo_log_only "Fixing socket for $u"
                sed -i 's/network.scgi.open_port.*/network.scgi.open_local = \/var\/run\/'${u}'\/.rtorrent.sock\nschedule2 = chmod_scgi_socket, 0, 0, "execute2=chmod,\\"g+w,o=\\",\/var\/run\/'${u}'\/.rtorrent.sock"/' /home/${u}/.rtorrent.rc
                restart=1
            fi
            if [ -f /install/.rutorrent.lock ]; then
                if ! grep -q /srv/rutorrent/php/initplugins.php /home/${u}/.rtorrent.rc; then
                    echo_log_only "fixing initplugins for $u"
                    sed -i 's:/var/www/rutorrent/php/initplugins.php:/srv/rutorrent/php/initplugins.php:g' /home/${u}/.rtorrent.rc
                    restart=1
                fi
            fi
        fi
        if [[ $restart = 1 ]]; then
            echo_log_only "restarting rutorrent for $u"
            systemctl try-restart rtorrent@${u}
        fi
        # TODO what about condition where the file does not exist? applies to the ones below as well
        if [[ -f /etc/nginx/apps/${u}.scgi.conf ]]; then
            if grep -q "scgi_pass 127.0.0.1" /etc/nginx/apps/${u}.scgi.conf; then
                echo_log_only "fixing nginx scgi for $u"
                sed -i 's/scgi_pass.*/scgi_pass unix:\/var\/run\/'${u}'\/.rtorrent.sock;/g' /etc/nginx/apps/${u}.scgi.conf
                systemctl reload nginx
            fi
        fi
        if [[ -f /srv/rutorrent/conf/users/${u}/config.php ]]; then
            if grep -q "scgi_host" /srv/rutorrent/conf/users/${u}/config.php; then
                :
            else
                echo_log_only "fixing socket in rutorrent for $u"
                sed -i 's/$scgi_port.*/$scgi_port = 0;\n$scgi_host = "unix:\/\/\/var\/run\/'${u}'\/.rtorrent.sock";/g' /srv/rutorrent/conf/users/${u}/config.php
                /usr/local/bin/swizzin/php-fpm-cli -r 'opcache_reset();'
            fi
        fi
        if [[ -f /home/${u}/.flood/config.js ]]; then
            if grep -q "socket: false" /home/${u}/.flood/config.js; then
                echo_log_only "fixing socket in flood for $u"
                sed -i "s/socket: false/socket: true/g" /home/${u}/.flood/config.js
                sed -i "s/socketPath.*/socketPath: '\/var\/run\/${u}\/.rtorrent.sock'/g" /home/${u}/.flood/config.js
                systemctl try-restart flood@${u}
            fi
        fi
    done

fi

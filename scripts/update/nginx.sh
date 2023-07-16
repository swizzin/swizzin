#!/bin/bash

function update_nginx() {
    codename=$(lsb_release -cs)

    case $codename in
        focal | buster | bullseye)
            mcrypt=
            geoip="php-geoip"
            ;;
        *)
            mcrypt=
            geoip=

            ;;
    esac

    #Deprecate nginx-extras in favour of installing fancyindex alone

    if dpkg -s nginx-extras > /dev/null 2>&1; then
        apt_remove nginx-extras
        apt_install nginx libnginx-mod-http-fancyindex
        apt_autoremove
        rm $(ls -d /etc/nginx/modules-enabled/*.removed)
        systemctl reload nginx
    fi
    LIST="php-fpm php-cli php-dev php-xml php-curl php-xmlrpc php-json php-mbstring php-opcache php-xml php-zip ${geoip} ${mcrypt}"

    missing=()
    for dep in $LIST; do
        if ! check_installed "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${missing[1]} != "" ]]; then
        # echo_inf "Installing the following dependencies: ${missing[*]}" | tee -a $log
        apt_install "${missing[@]}"
    fi

    cd /etc/php
    phpv=$(ls -d */ | cut -d/ -f1)
    if [[ $phpv =~ 7\\.1 ]]; then
        if [[ $phpv =~ 7\\.0 ]]; then
            apt_remove purge php7.0-fpm
        fi
    fi

    . /etc/swizzin/sources/functions/php
    phpversion=$(php_service_version)
    sock="php${phpversion}-fpm"

    for version in $phpv; do
        if [[ -f /etc/php/$version/fpm/php.ini ]]; then
            echo_progress_start "Updating config for PHP $version"
            sed -i -e "s/post_max_size = 8M/post_max_size = 64M/" \
                -e "s/upload_max_filesize = 2M/upload_max_filesize = 92M/" \
                -e "s/expose_php = On/expose_php = Off/" \
                -e "s/128M/768M/" \
                -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" \
                -e "s/;opcache.enable=0/opcache.enable=1/" \
                -e "s/;opcache.memory_consumption=64/opcache.memory_consumption=128/" \
                -e "s/;opcache.max_accelerated_files=2000/opcache.max_accelerated_files=4000/" \
                -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=240/" /etc/php/$version/fpm/php.ini
            phpenmod -v $version opcache
            sed -i 's/;env\[PATH\]/env[PATH]/g' /etc/php/$version/fpm/pool.d/www.conf
            echo_progress_done
        fi
    done

    if [[ ! -f /etc/nginx/modules-enabled/50-mod-http-fancyindex.conf ]]; then
        echo_progress_start "Enabling fancyindex module"
        mkdir -p /etc/nginx/modules-enabled/
        ln -s /usr/share/nginx/modules-available/mod-http-fancyindex.conf /etc/nginx/modules-enabled/50-mod-http-fancyindex.conf
        echo_progress_done
    fi

    phpversion=$(php_service_version)

    fcgis=($(find /etc/nginx -type f -exec grep -l "fastcgi_pass unix:/run/php/" {} \;))
    err=()
    for f in ${fcgis[@]}; do
        err+=($(grep -L "fastcgi_pass unix:/run/php/php${phpversion}-fpm.sock" $f))
    done
    for fix in ${err[@]}; do
        echo_progress_start "Updating PHP${phpversion} to use socket"
        sed -i "s/fastcgi_pass .*/fastcgi_pass unix:\/run\/php\/php${phpversion}-fpm.sock;/g" $fix
        echo_progress_done
    done

    if grep -q -e "-dark" -e "Nginx-Fancyindex" /srv/fancyindex/header.html; then
        echo_progress_start "Updating fancyindex theme"
        sed -i 's/href="\/[^\/]*/href="\/fancyindex/g' /srv/fancyindex/header.html
        echo_progress_done
    fi

    if grep -q "Nginx-Fancyindex" /srv/fancyindex/footer.html; then
        echo_progress_start "Updating fancyindex footer"
        sed -i 's/src="\/[^\/]*/src="\/fancyindex/g' /srv/fancyindex/footer.html
        echo_progress_done
    fi

    if [[ -f /install/.rutorrent.lock ]]; then
        if grep -q "php" /etc/nginx/apps/rindex.conf; then
            :
        else
            echo_progress_start "Updating rutorrent nginx config"
            cat > /etc/nginx/apps/rindex.conf << EOR
location /rtorrent.downloads {
  alias /home/\$remote_user/torrents/rtorrent;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;

  location ~* \.php$ {

  }
}
EOR
            echo_progress_done
        fi
    fi

    if [[ -f /install/.deluge.lock ]]; then
        if grep -q "php" /etc/nginx/apps/dindex.conf; then
            :
        else
            echo_progress_start "Updating deluge nginx config"
            cat > /etc/nginx/apps/dindex.conf << DIN
location /deluge.downloads {
  alias /home/\$remote_user/torrents/deluge;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;

  location ~* \.php$ {

  }
}
DIN
            echo_progress_done
        fi
    fi

    if [[ -f /install/.transmission.lock ]]; then
        if grep -q "php" /etc/nginx/apps/tmsindex.conf; then
            :
        else
            echo_progress_start "Updating transmission nginx config"
            cat > /etc/nginx/apps/tmsindex.conf << DIN
location /transmission.downloads {
  alias /home/\$remote_user/torrents/transmission;
  include /etc/nginx/snippets/fancyindex.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;

  location ~* \.php$ {

  }
}
DIN
            echo_progress_done
        fi
    fi

    # Remove php directive at the root level since we no longer use php
    # on root and we define php manually for nested locations
    if grep -q '\.php\$' /etc/nginx/sites-enabled/default; then
        echo_progress_start "Removing php directive from root location"
        sed -i -e '/location ~ \\.php$ {/,/}/d' /etc/nginx/sites-enabled/default
        echo_progress_done
    fi

    # Remove fancy index location block because it's now an app conf
    if grep -q 'fancyindex' /etc/nginx/sites-enabled/default; then
        echo_progress_start "Removing fancyindex location block"
        sed -i -e '/location \/fancyindex {/,/}/d' /etc/nginx/sites-enabled/default
        echo_progress_done
    fi

    # Create fancyindex conf if not exists
    if [[ ! -f /etc/nginx/apps/fancyindex.conf ]] || grep -q posterity /etc/nginx/apps/fancyindex.conf > /dev/null 2>&1; then
        echo_progress_start "Creating fancyindex app conf"
        cat > /etc/nginx/apps/fancyindex.conf << FIAC
location /fancyindex {
    location ~ \.php($|/) {
        fastcgi_split_path_info ^(.+?\.php)(/.+)$;
        # Work around annoying nginx "feature" (https://trac.nginx.org/nginx/ticket/321)
        set \$path_info \$fastcgi_path_info;
        fastcgi_param PATH_INFO \$path_info;

        try_files \$fastcgi_script_name =404;
        fastcgi_pass unix:/run/php/${sock}.sock;
        fastcgi_param SCRIPT_FILENAME \$request_filename;
        include fastcgi_params;
        fastcgi_index index.php;
    }
}
FIAC
        echo_progress_done

    fi

    if grep -q 'index.html' /etc/nginx/sites-enabled/default; then
        echo_progress_start "Removing index.html from root location"
        sed -i '/index.html/d' /etc/nginx/sites-enabled/default
        echo_progress_done
    fi

    # Upgrade SSL Protocols
    if grep -q 'ssl_protocols TLSv1 TLSv1.1 TLSv1.2;' /etc/nginx/snippets/ssl-params.conf; then
        echo_progress_start "Upgrading SSL Protocols"
        # Upgrades protocols to 1.2/1.3
        sed 's|ssl_protocols TLSv1 TLSv1.1 TLSv1.2;|ssl_protocols TLSv1.2 TLSv1.3;|g' -i /etc/nginx/snippets/ssl-params.conf
        # Changes cyphers
        sed 's|ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";|ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:EECDH+AESGCM:EDH+AESGCM;|g' -i /etc/nginx/snippets/ssl-params.conf
        echo_progress_done
    fi

    # Upgrade to http/2
    if grep -q 'listen 443 ssl default_server;' /etc/nginx/sites-enabled/default; then
        echo_progress_start "Upgrading to http/2"
        # IPV4 http2 upgrade
        sed 's|listen 443 ssl default_server;|listen 443 ssl http2 default_server;|g' -i /etc/nginx/sites-enabled/default
        # IPV6 http2 upgrade
        sed 's|listen \[::]\:443 ssl default_server;|listen \[::]\:443 ssl http2 default_server;|g' -i /etc/nginx/sites-enabled/default
        echo_progress_done
    fi

    #TODO: This needs an if statement
    # fix /etc/nginx/sites-enabled/default to not cause nginx to fail on reloading when there are subdirectories in /etc/nginx/apps like /etc/nginx/apps/authelia
    echo_progress_start "Fixing nginx for recursive configs"
    sed 's|include /etc/nginx/apps/\*;|include /etc/nginx/apps/\*.conf;|g' -i /etc/nginx/sites-enabled/default
    echo_progress_done

    #TODO: This needs an if statement
    echo_progress_start "Restarting php-fpm and nginx"
    #shellcheck source=sources/functions/php
    . /etc/swizzin/sources/functions/php
    restart_php_fpm
    systemctl reload nginx
    echo_progress_done
}

if [[ -f /install/.nginx.lock ]]; then update_nginx; fi

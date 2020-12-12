#!/bin/bash
# organizr installation wrapper

if [[ ! -f /install/.nginx.lock ]]; then
    echo_error "nginx does not appear to be installed, organizr requires a webserver to function. Please install nginx first before installing this package."
    exit 1
fi

#shellcheck source=sources/functions/php
. /etc/swizzin/sources/functions/php
phpversion=$(php_service_version)

if [[ $phpversion == '7.0' ]]; then
    echo_error "Your version of PHP is too old for Organizr"
    exit 1
fi

#This won't recurse into the nginx setup, please change that there manually if you wish to move it. I just found this convenient.
organizr_dir="/srv/organizr"

####### Source download
function organizr_install() {
    apt_install php-mysql php-sqlite3 sqlite3 php-xml php-zip openssl php-curl

    if [[ ! -d $organizr_dir ]]; then
        echo_progress_start "Cloning the Organizr Repo"
        git clone -b v2-master https://github.com/causefx/Organizr $organizr_dir --depth 1 >> "$log" 2>&1
        chown -R www-data:www-data $organizr_dir
        chmod 0700 -R $organizr_dir
        echo_progress_done "Organizr cloned"
    fi

    if [[ ! -d $organizr_dir ]]; then
        echo_error "Failed to clone the repository"
        exit 1
    fi
}

function organizr_nginx() {
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/organizr.sh
    systemctl reload nginx
    echo_progress_done
}

####### Databse bootstrapping
function organizr_setup() {
    mkdir ${organizr_dir}_db -p
    chown -R www-data:www-data ${organizr_dir}_db
    chmod 0700 -R $organizr_dir

    user=$(cut -d: -f1 < /root/.master.info)
    pass=$(cut -d: -f2 < /root/.master.info)

    #TODO check that passwords with weird characters will send right
    if [[ $user == "$pass" ]]; then
        echo_warn "Your username and password seem to be identical, please finish the Organizr setup manually."
    else

        api_key="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)"
        hash_key="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)"
        reg_pass="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)"
        form_key="$(php -r "echo password_hash(substr(\"$hash_key\", 2, 10), PASSWORD_BCRYPT);")"

        cat > /root/.organizr << EOF
api_key = $api_key
hash_key = $hash_key
reg_pass = $reg_pass
EOF
        echo_progress_start "Setting up the organizr database"

        curl --location --request POST 'https://127.0.0.1/organizr/api/v2/wizard' \
            --header 'content-type: application/x-www-form-urlencoded' \
            --header 'charset: UTF-8' \
            --header 'Content-Encoding: gzip' \
            --header 'Content-Type: application/x-www-form-urlencoded' \
            --data-urlencode "license=personal" \
            --data-urlencode "username=${user}" \
            --data-urlencode "email=${user}@localhost" \
            --data-urlencode "password=${pass}" \
            --data-urlencode "hashKey=${hash_key}" \
            --data-urlencode "registrationPassword=${reg_pass}" \
            --data-urlencode "api=${api_key}" \
            --data-urlencode "dbName=orgdb" \
            --data-urlencode "dbPath=${organizr_dir}_db" \
            --data-urlencode "formKey=${form_key}_db" \
            -sk >> "$log" 2>&1

        # sleep 10
        curl -k https://127.0.0.1/organizr/api/functions.php
        #shellcheck source=sources/functions/php
        . /etc/swizzin/sources/functions/php
        reload_php_opcache
        echo_progress_done "Organizr database set up and configured"
    fi
}
function organizr_f2b() {
    echo_progress_start "Setting up Fail2Ban for organizr"

    touch /srv/organizr_db/organizrLoginLog.json
    cat > /etc/fail2ban/filter.d/organizr-auth.conf << EOF
[Definition]
failregex = ","username":"\S+","ip":"<HOST>","auth_type":"error"}*
ignoreregex =
EOF

    cat > /etc/fail2ban/jail.d/organizr-auth.conf << EOF
[organizr-auth]
enabled = true
port = http,https
filter = organizr-auth
logpath = /srv/organizr_db/organizrLoginLog.json
ignoreip = 127.0.0.1/24
EOF

    fail2ban-client reload >> "$log" 2>&1
    echo_progress_done "Fail2Ban configured"
}

organizr_addusers() {
    #TODO implement when organizr API supports this
    echo_warn "Remember to manually create accounts for the user(s) in Organizr!"
    # #shellcheck source=sources/functions/utils
    # . /etc/swizzin/sources/functions/utils
    # #shellcheck source=sources/functions/organizr
    # . /etc/swizzin/sources/functions/organizr
    # for u in $users; do
    # 	:
    # 	echo_progress_start "Adding $u to organizr"
    # 	organizr_adduser "$u" "$u@localhost" "$(_get_user_password "$u")"
    # 	echo_progress_done "$u added to organizr"
    # done
}

#Catch script being called with parameter
if [[ -n $1 ]]; then
    users=$1

    organizr_addusers
    exit 0
fi

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
organizr_install
organizr_nginx
touch /install/.organizr.lock
organizr_setup
# Removing master because that's already done in the _setup
# shellcheck disable=SC2034 #(while addusers is commented)
mapfile -t users < <(_get_user_list | grep -vw "$(_get_master_username)")
organizr_addusers
organizr_f2b
echo_success "Organizr installed"
echo_info "Log in using your master credentials and configure your instance"

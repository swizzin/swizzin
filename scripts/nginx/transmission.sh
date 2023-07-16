#!/bin/bash
# nginx setup for transmission
# by liara for swizzin
# copyright 2020 swizzin.ltd

users=($(cut -d: -f1 < /etc/htpasswd))

if [[ ! -f /etc/nginx/apps/tmsindex.conf ]]; then
    cat > /etc/nginx/apps/tmsindex.conf << DIN
location /transmission.downloads {
    alias /home/\$remote_user/transmission/downloads;
    include /etc/nginx/snippets/fancyindex.conf;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd;

  location ~* \.php\$ {

  }
}
DIN
fi

if [[ ! -f /etc/nginx/apps/transmission.conf ]]; then
    cat > /etc/nginx/apps/transmission.conf << TCONF
location /transmission {
    return 301 /transmission/web/;
}

location /transmission/ {
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Host \$http_host;
    proxy_set_header X-NginX-Proxy true;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_pass_header X-Transmission-Session-Id;
    add_header   Front-End-Https   on;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd;
    proxy_pass http://\$remote_user.transmission;
}
TCONF
fi

for u in ${users[@]}; do
    active=$(systemctl is-active transmission@$u)
    echo_log_only "Service for $u was $active"
    if [[ $active == "active" ]]; then
        systemctl stop transmission@${u}
    fi

    timeout=0
    while systemctl is-active transmission@"$u" > /dev/null; do
        # echo "is active"
        timeout+=0.3
        if [[ $timeout -ge 20 ]]; then
            echo_error "The service transmission@$u took too long to shut down. Aborting."
            exit 1
        fi
        sleep 0.3
    done

    confpath="/home/${u}/.config/transmission-daemon/settings.json"
    jq '.["rpc-bind-address"] = "127.0.0.1"' "$confpath" >> /root/logs/swizzin.log
    RPCPORT=$(jq -r '.["rpc-port"]' < "$confpath")
    if [[ ! -f /etc/nginx/conf.d/${u}.transmission.conf ]]; then
        cat > /etc/nginx/conf.d/${u}.transmission.conf << TDCONF
upstream ${u}.transmission {
    server 127.0.0.1:${RPCPORT};
}
TDCONF
    fi
    if [[ $active == "active" ]]; then
        systemctl start transmission@${u}
        echo_log_only "Activating service"
    fi
done

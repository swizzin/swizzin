#! /bin/bash
# audiobookshelf nginx config 13378


MASTER=$(cut -d: -f1 < /root/.master.info)
if [[ ! -f /etc/nginx/apps/audiobookshelf.conf ]]; then
    cat > /etc/nginx/apps/audiobookshelf.conf << WEBC
location /audiobookshelf/ {
    include /etc/nginx/snippets/proxy.conf;

    # Tell nginx that we want to proxy everything here to the local audiobookshelf server
    # Last slash is important
    proxy_pass https://127.0.0.1:13378/;
    proxy_redirect https://\$host /audiobookshelf;
    proxy_set_header Host \$host:\$server_port;
    proxy_set_header Upgrade            $http_upgrade;
    proxy_set_header Connection         "upgrade";
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
WEBC
fi

systemctl restart audiobookshelf.service


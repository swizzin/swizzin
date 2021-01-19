#!/usr/bin/env bash

cat > /etc/nginx/apps/calibre-cs.conf << EOF
proxy_set_header X-Forwarded-For \$remote_addr;
location /calibre-cs/ {
    proxy_buffering         off;
    proxy_pass              http://127.0.0.1:8089\$request_uri;
    auth_basic              "What's the password?";
    auth_basic_user_file    /etc/htpasswd;
}
location /calibre-cs {
    # we need a trailing slash for the Application Cache to work
    rewrite                 /calibre-cs /calibre-cs/ permanent;
}
EOF

sed '/ExecStart=/ s/$/ --listen-on 127.0.0.1 --url-prefix \/calibre-cs --trusted-ips 127.0.0.1/' -i /etc/systemd/system/calibre-cs.service

systemctl daemon-reload
systemctl try-restart calibre-cs

#!/bin/bash
# Nginx Configurator for nzbget
# Author: liara

users=($(cut -d: -f1 < /etc/htpasswd))

if [[ ! -f /etc/nginx/apps/nzbget.conf ]]; then
    cat > /etc/nginx/apps/nzbget.conf << 'NRP'
location /nzbget {
  return 301 /nzbget/;
}

location /nzbget/ {
  include /etc/nginx/snippets/proxy.conf;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd;
  rewrite ^/nzbget/(.*) /$1 break;
  proxy_pass http://$remote_user.nzbget;
}
NRP
fi

for u in "${users[@]}"; do
    isactive=$(systemctl is-active nzbget@$u)
    sed -i "s/SecureControl=yes/SecureControl=no/g" /opt/nzbget/nzbget.conf
    sed -i "s/ControlIP=0.0.0.0/ControlIP=127.0.0.1/g" /opt/nzbget/nzbget.conf
    sed -i "s/ControlUsername=nzbget/ControlUsername=/g" /opt/nzbget/nzbget.conf
    sed -i "s/ControlPassword=tegbzn6789/ControlPassword=/g" /opt/nzbget/nzbget.conf

    if [[ ! -f /etc/nginx/conf.d/${u}.nzbget.conf ]]; then
        NZBPORT=$(grep ControlPort /home/$u/nzbget/nzbget.conf | cut -d= -f2)
        cat > /etc/nginx/conf.d/${u}.nzbget.conf << NZBUPS
upstream $u.nzbget {
  server 127.0.0.1:$NZBPORT;
}
NZBUPS
    fi

    if [[ $isactive == "active" ]]; then
        systemctl restart nzbget@$u
    fi
done

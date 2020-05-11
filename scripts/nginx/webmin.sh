#! /bin/bash
# Webmin nginx installer
# flying_sausages for swizzin 2020

MASTER=$(cut -d: -f1 < /root/.master.info)
if [[ ! -f /etc/nginx/apps/webmin.conf ]]; then
cat > /etc/nginx/apps/webmin.conf <<EMB
location /webmin/ {
    include /etc/nginx/snippets/proxy.conf;

    # Tell nginx that we want to proxy everything here to the local webmin server
    # Last slash is important
    proxy_pass https://127.0.0.1:10000/;
    proxy_set_header Host \$host:\$server_port;

    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
EMB
fi

_get_domain_for_webmin () {
    if [[ -z $webmin_referers ]]; then
        guess=$(grep -m1 "server_name" /etc/nginx/sites-enabled/default | awk '{print $2}' | sed 's/;//g')
        if [[ $guess = '_' ]]; then 
            guess=''
        fi
        if [[ -n $guess ]]; then
            guesstext="\nBelow is a possible match from your nginx configuration."
        fi
        webmin_referers=$(whiptail --inputbox "Enter your host's domain or IP address.\ne.g. \"sub.domain.com\", \"123.234.32.21\", etc.${guesstext}\nLeave empty to configure manually later" 10 50 "${guess}" 3>&1 1>&2 2>&3)
    fi
    echo "$webmin_referers"
}

#TODO figure out if there's a cleaner way to get this from nginx or something
#referers=$(_get_domain_for_webmin)
#if [[ -z $referers ]]; then 
#    echo "You can set the IP/fqdn manually in /etc/webmin/conf"
#else
#    echo "If you change domain/IP in the future, please edit /etc/webmin/config"
#fi

cat >> /etc/webmin/config << EOF
webprefix=/webmin
webprefixnoredir=1
referers=${referers}
EOF
cat >> /etc/webmin/miniserv.conf << EOF
bind=127.0.0.1
sockets=
EOF

systemctl reload webmin

systemctl reload nginx
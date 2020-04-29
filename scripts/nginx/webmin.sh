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
    # Change the response Location: header to come from our proxy directory, not the server
    # Fixes initial redirect after login
    proxy_redirect https://\$host:10000/ /webmin/;
    # Also fixes initial redirect after login
    proxy_set_header Host \$host;

    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
}
EMB
fi

systemctl reload nginx
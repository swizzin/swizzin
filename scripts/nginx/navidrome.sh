#!/bin/bash
# navidrome nginx conf
# byte 2021 for Swizzin

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
user=$(_get_master_username)
cat > /etc/nginx/apps/navidrome.conf <<- NGX
location /navidrome {
  proxy_pass        http://127.0.0.1:4533/navidrome;
  proxy_set_header Host \$proxy_host;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_redirect off;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
NGX
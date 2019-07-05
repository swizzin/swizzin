#!/bin/bash
# Nginx Configuration for RapidLeech
MASTER=$(cat /root/.master.info | cut -d: -f1)

if [[ -f /lib/systemd/system/php7.3-fpm.service ]]; then
  sock=php7.3-fpm
elif [[ -f /lib/systemd/system/php7.2-fpm.service ]]; then
  sock=php7.2-fpm
elif [[ -f /lib/systemd/system/php7.1-fpm.service ]]; then
  sock=php7.1-fpm
else
  sock=php7.0-fpm
fi

if [[ ! -f /etc/nginx/apps/rapidleech.conf ]]; then
  cat > /etc/nginx/apps/rapidleech.conf <<RAP
location /rapidleech {
  alias /home/${MASTER}/rapidleech/;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${MASTER};
  try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
  index index.php;
  allow all;
  location ~ \.php$
  {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/$sock.sock;
    #fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME /home/${MASTER}\$fastcgi_script_name;
  }
}
RAP
fi

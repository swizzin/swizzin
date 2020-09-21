#!/bin/bash
user=$(cut -d: -f1 < /root/.master.info)
isactive=$(systemctl is-active nzbhydra2)

if [[ $isactive == "active" ]]; then
  systemctl stop nzbhydra2
fi

sed -i '/ExecStart/c\ExecStart=/opt/nzbhydra2/nzbhydra2 --baseurl "/nzbhydra2" --host "127.0.0.1"' /etc/systemd/system/nzbhydra2.service
systemctl daemon-reload 

cat > /etc/nginx/apps/nzbhydra2.conf <<EOF
location /nzbhydra2 {
    proxy_pass http://127.0.0.1:5076/nzbhydra2;
    proxy_set_header        X-Real-IP			\$remote_addr;
    proxy_set_header        Host				\$host;
    proxy_set_header        Scheme				\$scheme;
    proxy_set_header        X-Forwarded-For		\$proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto	\$scheme;
    proxy_set_header        X-Forwarded-Host	\$host;
    proxy_redirect off;
    auth_basic "What's the password?";
    auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
EOF

if [[ $isactive == "active" ]]; then
  systemctl start nzbhydra2
  sleep 5
fi
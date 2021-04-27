#!/bin/bash

#ToDo this should all be grabbed from SwizDB; Need to ensure swizdb is updated for existing installs
servicename="radarr"
nginxname="radarr"
lockname="radarr"
appname_lower="radarr"
servicefile="/etc/systemd/system/$servicename.service"
appdir="/opt/Radarr"

if ! user="$(swizdb get $appname_lower/owner)"; then
    user=$(_get_master_username)
fi

appdatadir="/home/$user/.config/Radarr/"

if ask "Would you like to purge the configuration?" Y; then
    purgeapp="True"
else
    purgeapp="False"
fi

systemctl disable --now -q "$servicename"
rm "$servicefile"
systemctl daemon-reload -q
rm -rf "$appdir"

if [[ "$purgeapp" = "True" ]]; then
    rm -rf "$appdatadir"
fi

if [[ -f /install/.nginx.lock ]]; then
    rm "/etc/nginx/apps/$nginxname.conf"
    systemctl reload nginx >> "$log" 2>&1
fi

rm "/install/.$lockname.lock"

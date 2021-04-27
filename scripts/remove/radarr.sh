#!/bin/bash

#ToDo this should all be grabbed from SwizDB; Need to ensure swizdb is updated for existing installs
servicename="radarr"
nginxname="radarr"
lockname="radarr"
appname="radarr"
servicefile="/etc/systemd/system/$servicename.service"
appdir="/opt/Radarr"

if ! app_user="$(swizdb get $appname/owner)"; then
    app_user=$(_get_master_username)
fi

appdatadir="/home/$app_user/.config/{$appname^}/"
# this must be set AFTER we get the app_user

if ask "Would you like to purge the configuration?" Y; then
    purgeapp="True"
    echo_info "Application Data Directory to delete & purge detected as $appdatadir"
else
    purgeapp="False"
fi
echo_progress_start "Removing {$appname^}..."

echo_progress_start "Disabling $servicename service and removing file"
systemctl disable --now -q "$servicename"
rm "$servicefile"
systemctl daemon-reload -q
echo_log_only "Disabled service $servicename and removed service file $servicefile"
echo_progress_done "Service disabled and removed"

echo_progress_start "Removing application files"
rm -rf "$appdir"
echo_progress_done "Application files removed"

if [[ "$purgeapp" = "True" ]]; then
    rm -rf "$appdatadir"
    echo_info "Application data purged"
fi

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Removing nginx conf"
    rm "/etc/nginx/apps/$nginxname.conf"
    systemctl reload nginx >> "$log" 2>&1
    echo_progress_done "Nginx conf removed"
fi

rm "/install/.$lockname.lock"
echo_progress_done "{$appname^} removed sucessfully"

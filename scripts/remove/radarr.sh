#!/bin/bash

app_name="radarr"
app_servicename="$(swizdb get "$app_name/servicename")"
app_servicefile="$(swizdb get "$app_name/servicefile")"
app_nginxname="$(swizdb get "$app_name/nginxname")"
app_lockname="$(swizdb get "$app_name/lockname")"
app_dir="$(swizdb get "$app_name/dir")"
app_datadir="$(swizdb get $app_name/datadir)"

if ask "Would you like to purge the configuration?" Y; then
    purgeapp="True"
    echo_info "Application Data Directory to delete & purge detected as $app_datadir"
else
    purgeapp="False"
fi
echo_progress_start "Removing ${app_name^}..."

echo_progress_start "Disabling $app_servicename service and removing file"
systemctl disable --now -q "$app_servicename"
rm "$app_servicefile"
systemctl daemon-reload -q
echo_log_only "Disabled service $app_servicename and removed service file $app_servicefile"
echo_progress_done "Service disabled and removed"

echo_progress_start "Removing application files"
rm -rf "$app_dir"
echo_progress_done "Application files removed"

if [[ "$purgeapp" = "True" ]]; then
    rm -rf "$app_datadir"
    echo_info "Application data purged"
fi

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Removing nginx conf"
    rm "/etc/nginx/apps/$app_nginxname.conf"
    systemctl reload nginx >> "$log" 2>&1
    echo_progress_done "Nginx conf removed"
fi

rm "/install/.$app_lockname.lock"
echo_progress_done "${app_name^} removed sucessfully"

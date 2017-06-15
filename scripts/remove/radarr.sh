#!/bin/sh
systemctl stop radarr
systemctl disable radarr
rm -rf /etc/systemd/system/radarr.service
rm -rf /opt/Radarr
rm -rf /etc/apache2/sites-enabled/radarr.conf
rm -rf /install/.radarr.lock
echo "Radarr uninstalled!"

#!/bin/bash
systemctl disable ombi
systemctl stop ombi
rm /etc/systemd/system/ombi.service
rm -f /etc/apache2/sites-enabled/ombi.conf
service apache2 reload
rm -rf /opt/ombi
rm /install/.ombi.lock

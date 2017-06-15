#!/bin/bash
systemctl stop plexpy
systemctl disable plexpy
rm -rf /opt/plexpy
rm /install/.plexpy.lock
rm -f /etc/apache2/sites-enabled/plexpy.conf
service apache2 reload
rm /etc/systemd/system/plexpy.service

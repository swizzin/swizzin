#!/bin/bash

rm -rf /srv/panel
rm -f /etc/nginx/apps/panel.conf
rm -f /etc/sudoers.d/panel
rm /etc/cron.d/set_interface
rm /install/.panel.lock
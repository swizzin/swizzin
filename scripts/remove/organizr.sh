#!/bin/bash
# Organizr removal
# Author: flying_sausages for Swizzin 2020

rm -rf /srv/organizr
rm -rf /srv/organizr_db
rm -rf /etc/nginx/apps/organizr.conf
rm -rf /install/.organizr.lock
systemctl reload nginx
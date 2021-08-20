#!/bin/bash
# LazyLibrarian remove script for swizzin
# Author: Aethaeran

##########################################################################
# Import Sources
##########################################################################

. /etc/swizzin/sources/functions/utils

##########################################################################
# Variables
##########################################################################

app_name=lazylibrarian
pretty_name=LazyLibrarian
app_dir="/opt/$app_name"
master=$(_get_master_username)
config_dir="/home/$master/.config/lazylibrarian"

##########################################################################
# Main
##########################################################################

rm -rv "$app_dir" >> $log 2>&1

rm -rv "$config_dir" >> $log 2>&1

systemctl disable --now --quiet $app_name
rm -v "/etc/systemd/system/$app_name.service" >> $log 2>&1
#rm -v "/etc/systemd/system/$app_name@.service" >> $log 2>&1

rm -v "/etc/nginx/apps/$app_name.conf" >> $log 2>&1

rm -v "/install/.$app_name.lock" >> $log 2>&1

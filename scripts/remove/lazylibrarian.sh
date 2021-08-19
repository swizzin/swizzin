#!/bin/bash
# LazyLibrarian remove script for swizzin
# Author: Aethaeran
app_name=lazylibrarian
pretty_name=LazyLibrarian
app_dir="/opt/$app_name"
config_dir="/home/$master/.config/lazylibrarian"
master=

rm -rv "$app_dir"
rm -rv "$config_dir"
rm -v "/etc/systemd/system/$app_name.service"
#rm -v "/etc/systemd/system/$app_name@.service"
rm -v "/etc/nginx/apps/$app_name.conf"

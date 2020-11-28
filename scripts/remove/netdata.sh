#! /bin/bash
# Netdata uninstaller for swizzin

systemctl disable -q netdata > /dev/null 2>&1
systemctl stop -q netdata
rm -rf $(which netdata)
rm -rf /etc/netdata
rm -rf /var/log/netdata
rm -rf /install/.netdata.lock

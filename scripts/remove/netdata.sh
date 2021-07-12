#! /bin/bash
# Netdata uninstaller for swizzin

"${NETDATA_PREFIX}"/usr/libexec/netdata/netdata-uninstaller.sh --yes --env /etc/netdata/.environment

systemctl disable -q netdata > /dev/null 2>&1
systemctl stop -q netdata
rm -rf $(which netdata)
rm -rf /etc/netdata
rm -rf /var/log/netdata
rm -rf /install/.netdata.lock

#! /bin/bash
# wg-dashbor yeeter
#

systemctl disable --now wg-dashboard
rm -rf /opt/wg-dashboard
rm /etc/systemd/system/wg-dashboard.service
systemctl daemon-reload
# shellcheck source=sources/functions/coredns
. /etc/swizzin/sources/functions/coredns
_remove_coredns

rm /install/.wg-dashboard.lock
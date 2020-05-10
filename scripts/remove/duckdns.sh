#! /bin/bash
#duckdns yeeter
#flying_sausages 2020 swizzin gplv3 respect mah autooritah

rm -rf /opt/duckdns
crontab -l | grep -v '/opt/duckdns'  | crontab -
echo "DuckDNS Removed"
echo
echo "DuckDNS will keep pointing the domain to the IP until it is set to something else or is deleted"

rm /install/.duckdns.lock
#! /bin/bash
#duckdns yeeter
#flying_sausages 2020 swizzin gplv3 respect mah autooritah
# shellcheck disable=SC2154

eval "$(grep subdomain /opt/duckdns/duck.sh | head -1)"
eval "$(grep token /opt/duckdns/duck.sh | head -1)"

echo -n "Clearing set IP for $subdomain.duckdns.org... "
echo url="https://www.duckdns.org/update?domains=$subdomain&token=$token&clear=true" | curl -k -K -
echo
rm -rf /opt/duckdns
crontab -l | grep -v '/opt/duckdns'  | crontab -
echo "DuckDNS Removed"

rm /install/.duckdns.lock
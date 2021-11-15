#!/bin/bash

user=$(grep User= /etc/systemd/system/sonarr.service | cut -d= -f2)
if ask "Would you like to purge the configuration?" Y; then
    if [[ -d /home/${user}/.config/Sonarr ]]; then
        rm -rf "/home/${user}/.config/Sonarr"
    fi
fi
rm -rf /opt/Sonarr
if [[ -f /install/.nginx.lock ]]; then
    rm /etc/nginx/apps/sonarr.conf
    systemctl reload nginx >> "$log" 2>&1
fi

#Mark mono depends as automatically installed
LIST='mono-runtime
    ca-certificates-mono
    libmono-system-net-http4.0-cil
    libmono-corlib4.5-cil
    libmono-microsoft-csharp4.0-cil
    libmono-posix4.0-cil
    libmono-system-componentmodel-dataannotations4.0-cil
    libmono-system-configuration-install4.0-cil
    libmono-system-configuration4.0-cil
    libmono-system-core4.0-cil
    libmono-system-data-datasetextensions4.0-cil
    libmono-system-data4.0-cil
    libmono-system-identitymodel4.0-cil
    libmono-system-io-compression4.0-cil
    libmono-system-numerics4.0-cil
    libmono-system-runtime-serialization4.0-cil
    libmono-system-security4.0-cil
    libmono-system-servicemodel4.0a-cil
    libmono-system-serviceprocess4.0-cil
    libmono-system-transactions4.0-cil
    libmono-system-web4.0-cil
    libmono-system-xml-linq4.0-cil
    libmono-system-xml4.0-cil
    libmono-system4.0-cil'

apt-mark auto ${LIST} >> ${log} 2>&1

#Remove mono if no longer required
apt-get autoremove -y >> ${log} 2>&1
rm -f /etc/apt/sources.list.d/mono-xamarin.list*
rm -f /etc/systemd/system/sonarr.service

rm /install/.sonarr.lock

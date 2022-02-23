#!/bin/bash

if [[ -f /install/.sonarr.lock ]]; then
    #Check if mono needs an update
    . /etc/swizzin/sources/functions/mono
    mono_repo_update
    systemctl try-restart sonarr
fi

if dpkg -l | grep nzbdrone > /dev/null 2>&1; then
    v2present=true
    echo_warn "Sonarr v2 is obsolete and end-of-life. Please upgrade your Sonarr to v3 using \`box upgrade sonarr\`."
fi
if [[ -f /install/.sonarr.lock ]] && [[ $v2present == "true" ]]; then
    echo_info "box package sonarr is being renamed to sonarrold"
    #update lock file
    rm /install/.sonarr.lock
    if [[ -f /install/.nginx.lock ]]; then
        mv /etc/nginx/apps/sonarr.conf /etc/nginx/apps/sonarrold.conf
        systemctl reload nginx
    fi
    touch /install/.sonarrold.lock
fi
if [[ -f /install/.sonarrv3.lock ]]; then
    echo_info "box package sonarrv3 is being renamed to sonarr as it has been released as stable"
    #upgrade sonarr v3 lock
    if [[ -f /install/.nginx.lock ]]; then
        mv /etc/nginx/apps/sonarrv3.conf /etc/nginx/apps/sonarr.conf
        systemctl reload nginx
    fi
    rm /install/.sonarrv3.lock
    touch /install/.sonarr.lock
fi
if [[ -f /install/.sonarr.lock ]] && dpkg -l | grep sonarr | grep ^ii > /dev/null 2>&1; then
    echo_info "Migrating Sonarr away from apt management"
    isActive=$(systemctl is-active sonarr)
    isEnabled=$(systemctl is-enabled sonarr)
    cp -a /usr/lib/sonarr/bin /opt/Sonarr
    if [[ ! -f /lib/systemd/system/sonarr.service ]]; then
        echo_error "A required file for the update could not be found: /lib/systemd/system/sonarr.service . Is your current Sonarr installation in a proper state?"
        exit 1
    fi
    cp /lib/systemd/system/sonarr.service /etc/systemd/system
    user=$(grep User= /etc/systemd/system/sonarr.service | cut -d= -f2)
    if [[ -z ${user} ]]; then
        echo_error "Could not determine the owner of Sonarr"
        exit 1
    fi
    echo_info "Moving config to '/home/${user}/.config/Sonarr'"
    mv /home/${user}/.config/sonarr /home/${user}/.config/Sonarr

    #Remove comments
    sed -i '/^#/d' /etc/systemd/system/sonarr.service
    #Update binary location
    sed -i 's|/usr/lib/sonarr/bin|/opt/Sonarr|g' /etc/systemd/system/sonarr.service
    sed -i "s|/home/${user}/.config/sonarr|/home/${user}/.config/Sonarr|g" /etc/systemd/system/sonarr.service

    #Mark depends as manually installed
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
        libmono-system4.0-cil
        sqlite3
        mediainfo'

    apt_install ${LIST}

    apt_remove --purge sonarr
    rm -rf /var/lib/sonarr
    rm -rf /usr/lib/sonarr
    rm -f /etc/apt/sources.list.d/sonarr.list*
    systemctl daemon-reload

    #Restart sonarr because apt-removal stops it
    if [[ $isActive == "active" ]]; then
        systemctl start sonarr
    fi

    #Update broken symlink to old service
    if [[ $isEnabled == "enabled" ]]; then
        systemctl enable sonarr >> ${log} 2>&1
    fi

fi

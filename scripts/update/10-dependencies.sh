#!/bin/bash
# Ensures that dependencies are installed and corrects them if that is not the case.

#space-separated list of required GLOBAL SWIZZIN dependencies (NOT application specific ones)
dependencies="whiptail git sudo curl wget lsof fail2ban apache2-utils vnstat tcl tcl-dev build-essential dirmngr apt-transport-https bc uuid-runtime jq net-tools fortune gnupg2 cracklib-runtime software-properties-common"

missing=()
for dep in $dependencies; do
    if ! check_installed "$dep"; then
        missing+=("$dep")
    fi
done

if [[ ${missing[0]} != "" ]]; then
    echo_info "Installing missing dependencies"
    apt_install "${missing[@]}"
else
    echo_log_only "No dependencies required to install"
fi

if [[ $(_os_distro) == "Debian" ]]; then
    if ! grep -q contrib /etc/apt/sources.list; then
        echo_info "Enabling contrib repo"
        apt-add-repository contrib >> ${log} 2>&1
        trigger_apt_update=true
    fi
    if ! grep -q non-free /etc/apt/sources.list; then
        echo_info "Enabling non-free repo"
        apt-add-repository non-free >> ${log} 2>&1
        trigger_apt_update=true
    fi
    if [[ $trigger_apt_update == "true" ]]; then
        apt_update
    fi
fi

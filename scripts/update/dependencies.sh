#! /bin/bash
# Ensures that dependencies are installed and corrects them if that is not the case.
if [[ -z $log ]]; then log="/root/logs/swizzin.log"; fi

#space-separated list of required GLOBAL SWIZZIN dependencies (NOT application specific ones)
dependencies="jq sl uuid-runtime"

missing=()
for dep in $dependencies; do
    if ! check_installed "$dep"; then 
        missing+=("$dep")
    fi
done

if [[ ${missing[1]} != "" ]]; then 
    echo "Installing the following dependencies: ${missing[*]}" | tee -a $log
    apt_install "${missing[@]}"
else
    echo "No dependencies required to install" >> $log
fi
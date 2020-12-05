#! /bin/bash
# Ensures that dependencies are installed and corrects them if that is not the case.

#space-separated list of required GLOBAL SWIZZIN dependencies (NOT application specific ones)
dependencies="jq uuid-runtime net-tools fortune-mod cowsay"

missing=()
for dep in $dependencies; do
	if ! check_installed "$dep"; then
		echo_log_only "$dep is missing"
		missing+=("$dep")
	fi
done

if [[ ${missing[0]} != "" ]]; then
	echo_info "Installing the following dependencies: ${missing[*]}"
	apt_install "${missing[@]}"
else
	echo_log_only "No dependencies required to install"
fi

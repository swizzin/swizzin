#!/usr/bin/env bash
#
# authors: liara userdocs flying-sausages
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
########
######## Variables Start
########
#
# Source the global functions we require for this script.
. /etc/swizzin/sources/functions/utils
. /etc/swizzin/sources/functions/ssl
#
# awaiting pull to remove
function dist_info() {
    DIST_CODENAME="$(source /etc/os-release && echo "$VERSION_CODENAME")"
    DIST_ID="$(source /etc/os-release && echo "$ID")"
}
#
# Get our some useful information from functions in the sourced utils script
username="$(_get_master_username)"
dist_info # get our distribution ID, set to DIST_ID, and VERSION_CODENAME, set to DIST_CODENAME, from /etc/os-release

if [[ $(systemctl is-active emby) == "active" ]]; then
    active=emby
fi

if [[ -n $active ]]; then
    echo_info "Jellyfin and Emby cannot be active at the same time.\nDo you want to disable $active and continue with the installation?\nDon't worry, your install will remain"
    if ask "Do you want to disable $active?" Y; then
        disable=yes
    fi
    if [[ $disable == "yes" ]]; then
        echo_progress_start "Disabling service"
        systemctl disable -q --now ${active} >> ${log} 2>&1
        echo_progress_done
    else
        exit 1
    fi
fi

#
########
######## Variables End
########
#
########
######## Application script starts.
########
#
# Generate the ssl certificates using the sourced function.
create_self_ssl "${username}"
#
# Generate our NET core ssl format cert from the default certs created using the ssl function and give it the required permissions.
openssl pkcs12 -export -nodes -out "/home/${username}/.ssl/${username}-self-signed.pfx" -inkey "/home/${username}/.ssl/${username}-self-signed.key" -in "/home/${username}/.ssl/${username}-self-signed.crt" -passout pass:
chown "${username}.${username}" -R "/home/${username}/.ssl"
chmod -R g+r "/home/${username}/.ssl"
#
# Create the required directories for this application.
mkdir -p /etc/jellyfin
chmod 755 /etc/jellyfin
#
# Create the dnla.xml so that we can Disable DNLA
cat > /etc/jellyfin/dlna.xml <<- CONFIG
	<?xml version="1.0"?>
	<DlnaOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	  <EnablePlayTo>false</EnablePlayTo>
	  <EnableServer>false</EnableServer>
	  <EnableDebugLog>false</EnableDebugLog>
	  <BlastAliveMessages>false</BlastAliveMessages>
	  <SendOnlyMatchedHost>true</SendOnlyMatchedHost>
	  <ClientDiscoveryIntervalSeconds>60</ClientDiscoveryIntervalSeconds>
	  <BlastAliveMessageIntervalSeconds>1800</BlastAliveMessageIntervalSeconds>
	</DlnaOptions>
CONFIG
#
# Create the system.xml. This is the applications main configuration file.
cat > /etc/jellyfin/system.xml <<- CONFIG
	<?xml version="1.0"?>
	<ServerConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	  <IsStartupWizardCompleted>false</IsStartupWizardCompleted>
	  <EnableUPnP>false</EnableUPnP>
	  <EnableHttps>true</EnableHttps>
	  <CertificatePath>/home/${username}/.ssl/${username}-self-signed.pfx</CertificatePath>
	  <IsPortAuthorized>true</IsPortAuthorized>
	  <EnableRemoteAccess>true</EnableRemoteAccess>
	  <BaseUrl />
	  <LocalNetworkAddresses>
		<string>0.0.0.0</string>
	  </LocalNetworkAddresses>
	  <RequireHttps>true</RequireHttps>
	</ServerConfiguration>
CONFIG
#
# Add the jellyfin official repository and key to our installation so we can use apt-get to install it jellyfin and jellyfin-ffmepg.
wget -q -O - "https://repo.jellyfin.org/$DIST_ID/jellyfin_team.gpg.key" | apt-key add - >> "${log}" 2>&1
echo "deb [arch=$(dpkg --print-architecture)] https://repo.jellyfin.org/$DIST_ID $DIST_CODENAME main" > /etc/apt/sources.list.d/jellyfin.list
#
# install jellyfin and jellyfin-ffmepg using apt functions.
apt_update #forces apt refresh
apt_install jellyfin jellyfin-ffmpeg
#
# Add the jellyfin user to the master user's group.
usermod -a -G "${username}" jellyfin
#
chown jellyfin:jellyfin /etc/jellyfin/dlna.xml
chown jellyfin:jellyfin /etc/jellyfin/system.xml
chown jellyfin:root /etc/jellyfin/logging.json
chown jellyfin:adm /etc/jellyfin
#
# Configure the nginx proxypass using positional parameters.
if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/jellyfin.sh
    systemctl -q restart nginx.service
fi
#
# Restart the jellyfin service to make sure our changes take effect
systemctl -q restart "jellyfin.service"
#
# This file is created after installation to prevent reinstalling. You will need to remove the app first which deletes this file.
touch /install/.jellyfin.lock
#
echo_success "Jellyfin installed"
#
exit

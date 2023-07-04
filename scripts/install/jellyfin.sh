#!/usr/bin/env bash
#
# authors: liara userdocs flying-sausages katiethedev
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
# Get our some useful information from functions in the sourced utils script
username="$(_get_master_username)"

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

ARCHITECTURE="$(dpkg --print-architecture)"
BASE_OS="$(awk -F'=' '/^ID=/{ print $NF }' /etc/os-release)"

# Handle some known alternative base OS values with 1-to-1 mappings
# Use the result as the repository base OS
case "${BASE_OS}" in
    raspbian)
        # Raspbian uses the Debian repository
        REPO_OS="debian"
        ;;
    linuxmint)
        # Linux Mint can either be Debian- or Ubuntu-based, so pick the right one
        if grep -q "DEBIAN_CODENAME=" /etc/os-release &> /dev/null; then
            VERSION="$(awk -F'=' '/^DEBIAN_CODENAME=/{ print $NF }' /etc/os-release)"
            REPO_OS="debian"
        else
            VERSION="$(awk -F'=' '/^UBUNTU_CODENAME=/{ print $NF }' /etc/os-release)"
            REPO_OS="ubuntu"
        fi
        ;;
    neon)
        # Neon uses the Ubuntu repository
        REPO_OS="ubuntu"
        ;;
    *)
        REPO_OS="${BASE_OS}"
        VERSION="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
        ;;
esac

#
## Get the path to gpg or install it
GNUPG=$(which gpg)
if [[ -z ${GNUPG} ]]; then
    echo "Failed to find the GNUPG binary, but we'll install 'gnupg' automatically."
    # shellcheck disable=SC2206
    # We are OK with word-splitting here since we control the contents
    INSTALL_PKGS=(${INSTALL_PKGS[@]} gnupg)
    echo
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
chown "${username}:${username}" -R "/home/${username}/.ssl"
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
#cat > /etc/jellyfin/system.xml <<- CONFIG
#	<?xml version="1.0"?>
#	<ServerConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
#	  <IsStartupWizardCompleted>false</IsStartupWizardCompleted>
#	  <IsPortAuthorized>true</IsPortAuthorized>
#	</ServerConfiguration>
#CONFIG

# Create the network.xml. This is the applications network configuration file.
cat > /etc/jellyfin/network.xml <<- CONFIG
<?xml version="1.0" encoding="utf-8"?>
<NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <RequireHttps>false</RequireHttps>
  <CertificatePath>/home/${username}/.ssl/${username}-self-signed.pfx</CertificatePath>
  <CertificatePassword />
  <BaseUrl />
  <PublicHttpsPort>8920</PublicHttpsPort>
  <HttpServerPortNumber>8096</HttpServerPortNumber>
  <HttpsPortNumber>8920</HttpsPortNumber>
  <EnableHttps>true</EnableHttps>
  <PublicPort>8096</PublicPort>
  <EnableIPV6>false</EnableIPV6>
  <EnableIPV4>true</EnableIPV4>
  <IgnoreVirtualInterfaces>true</IgnoreVirtualInterfaces>
  <VirtualInterfaceNames>vEthernet*</VirtualInterfaceNames>
  <TrustAllIP6Interfaces>false</TrustAllIP6Interfaces>
  <PublishedServerUriBySubnet />
  <RemoteIPFilter />
  <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>
  <EnableUPnP>false</EnableUPnP>
  <EnableRemoteAccess>true</EnableRemoteAccess>
  <LocalNetworkSubnets />
  <LocalNetworkAddresses />
  <KnownProxies />
</NetworkConfiguration>
CONFIG

#
# Check if old, outdated repository for jellyfin is installed
# If old repository is found, delete it.
if [[ -f /etc/apt/sources.list.d/jellyfin.list ]]; then
    echo_progress_start "Found old-style '/etc/apt/sources.list.d/jellyfin.list' configuration; removing it."
    rm -f /etc/apt/sources.list.d/jellyfin.list
    echo_progress_done "Removed old configuration."
    echo_success "Old repository has been removed."
fi

#
# Add Jellyfin signing key
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor --yes --output /etc/apt/keyrings/jellyfin.gpg
echo_success "Jellyfin Signing Key Added"

#
# Install the Deb822 format jellyfin.sources entry
echo_progress_start "Adding Jellyfin repository to apt."
cat << EOF | tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${REPO_OS}
Suites: ${VERSION}
Components: main
Architectures: ${ARCHITECTURE}
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
echo_progress_done "Jellyfin repository added."

#
# Update apt repositories to fetch Jellyfin repository
apt_update #forces apt refresh

#
# Install Jellyfin and dependencies using apt
# Dependencies are automatically grabbed by apt
apt_install jellyfin

#
# Make sure Jellyfin finishes starting up before continuing.
echo_progress_start "Waiting for Jellyfin to start."
sleep 15
echo_progress_done "Jellyfin should be started."

#
# Add the jellyfin user to the master user's group.
usermod -a -G "${username}" jellyfin
#

chown jellyfin:jellyfin /etc/jellyfin/dlna.xml
chown jellyfin:jellyfin /etc/jellyfin/network.xml
chown jellyfin:root /etc/jellyfin/logging.default.json
chown jellyfin:adm /etc/jellyfin
#
# Configure the nginx proxypass using positional parameters.
if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/jellyfin.sh
    systemctl -q restart nginx.service
else
    echo_info "Jellyfin will run on port 8920"
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

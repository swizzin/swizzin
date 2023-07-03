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

ARCHITECTURE="$(dpkg --print-architecture)"
BASE_OS="$(awk -F'=' '/^ID=/{ print $NF }' /etc/os-release)"

SUPPORTED_ARCHITECTURES='@(amd64|armhf|arm64)'
SUPPORTED_DEBIAN_RELEASES='@(buster|bullseye|bookworm)'
SUPPORTED_UBUNTU_RELEASES='@(trusty|xenial|bionic|cosmic|disco|eoan|focal|groovy|hirsute|impish|jammy|kinetic|lunar)'

# Validate that we're running on a supported (dpkg) architecture
# shellcheck disable=SC2254
# We cannot quote this extglob expansion or it doesn't work
case "${ARCHITECTURE}" in
    ${SUPPORTED_ARCHITECTURES})
        true
        ;;
    *)
        echo "Sorry, Jellyfin doesn't support the CPU architecture '${ARCHITECTURE}'."
        exit 1
        ;;
esac

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

# Validate that we're running a supported release (variables at top of file)
case "${REPO_OS}" in
    debian)
        # shellcheck disable=SC2254
        # We cannot quote this extglob expansion or it doesn't work
        case "${VERSION}" in
            ${SUPPORTED_DEBIAN_RELEASES})
                true
                ;;
            *)
                echo "Sorry, we don't support the Debian codename '${VERSION}'."
                exit 1
                ;;
        esac
        ;;
    ubuntu)
        # shellcheck disable=SC2254
        # We cannot quote this extglob expansion or it doesn't work
        case "${VERSION}" in
            ${SUPPORTED_UBUNTU_RELEASES})
                true
                ;;
            *)
                echo "Sorry, we don't support the Ubuntu codename '${VERSION}'."
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Sorry, we don't support the base OS '${REPO_OS}'."
        exit 1
        ;;
esac

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
# Make sure universe is enabled so that ffmpeg can be satisfied.
sudo add-apt-repository universe

#
# Check if old, outdated repository for jellyfin is installed
# If old repository is found, delete it.
if [[ -f /etc/apt/sources.list.d/jellyfin.list ]]; then
    echo "> Found old-style '/etc/apt/sources.list.d/jellyfin.list' configuration; removing it."
    rm -f /etc/apt/sources.list.d/jellyfin.list
fi

#
# Add Jellyfin signing key
echo "> Fetching repository signing key."
$FETCH https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor --yes --output /etc/apt/keyrings/jellyfin.gpg

#
# Install the Deb822 format jellyfin.sources entry
echo "> Installing Jellyfin repository into APT."
cat << EOF | tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${REPO_OS}
Suites: ${VERSION}
Components: main
Architectures: ${ARCHITECTURE}
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
echo

#
# Update apt repositories to fetch Jellyfin repository
apt_update #forces apt refresh

#
# Install Jellyfin and dependencies using apt
# Dependencies are automatically grabbed by apt
apt_install jellyfin

#
# Make sure Jellyfin finishes starting up before continuing.
echo "> Waiting 15 seconds for Jellyfin to fully start up."
sleep 15

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

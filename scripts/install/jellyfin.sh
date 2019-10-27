#!/bin/bash
#
# [Swizzin :: Install Jellyfin package]
#
# Author: liara
#
# swizzin Copyright (C) 2019 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
########
######## Variables Start
########

# Get our main user credentials.
username="$(cut </root/.master.info -d: -f1)"

# This will generate a random port for the script between the range 10001 to 32001 to use with applications.
app_port_http="$(shuf -i 10001-32001 -n 1)" && while [[ "$(ss -ln | grep -co ''"${app_port_http}"'')" -ge "1" ]]; do app_port_http="$(shuf -i 10001-32001 -n 1)"; done
app_port_https="$(shuf -i 10001-32001 -n 1)" && while [[ "$(ss -ln | grep -co ''"${app_port_https}"'')" -ge "1" ]]; do app_port_https="$(shuf -i 10001-32001 -n 1)"; done

ip_address="$(curl -s4 icanhazip.com)"
########
######## Variables End
########

########
######## Application script starts.
########

# Source the global functions we require.
. /etc/swizzin/sources/functions/ssl

create_self_ssl "${username}"

if [[ ! -f /home/"${username}"/.ssl/"${username}" ]]; then
  openssl pkcs12 -export -nodes -out /home/"${username}"/.ssl/"${username}"-self-signed.pfx -inkey /home/"${username}"/.ssl/"${username}"-self-signed.key -in /home/"${username}"/.ssl/"${username}"-self-signed.crt -passout pass:
fi

# Create the required directories for this application.
mkdir -p "/home/${username}/.jellyfin"
mkdir -p "/home/${username}/.config/Jellyfin/config"

# Download and extract the files to the desired location.
wget -qO "/home/${username}/jellyfin.tar.gz" "$(curl -s https://api.github.com/repos/jellyfin/jellyfin/releases/latest | grep -Po 'ht(.*)linux-amd64(.*)gz')" >/dev/null 2>&1
tar -xvzf "/home/${username}/jellyfin.tar.gz" --strip-components=1 -C "/home/${username}/.jellyfin" >/dev/null 2>&1

# Removes the archive as we no longer need it.
rm -f "/home/${username}/jellyfin.tar.gz" >/dev/null 2>&1

# Create the configuration file.
cat >"/home/${username}/.config/Jellyfin/config/system.xml" <<-CONFIG
<?xml version="1.0"?>
<ServerConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <LogFileRetentionDays>3</LogFileRetentionDays>
  <IsStartupWizardCompleted>false</IsStartupWizardCompleted>
  <EnableUPnP>false</EnableUPnP>
  <PublicPort>${app_port_http}</PublicPort>
  <PublicHttpsPort>${app_port_https}</PublicHttpsPort>
  <HttpServerPortNumber>${app_port_http}</HttpServerPortNumber>
  <HttpsPortNumber>${app_port_https}</HttpsPortNumber>
  <EnableHttps>true</EnableHttps>
  <EnableNormalizedItemByNameIds>false</EnableNormalizedItemByNameIds>
  <CertificatePath>/home/${username}/.ssl/${username}-self-signed.pfx</CertificatePath>
  <IsPortAuthorized>true</IsPortAuthorized>
  <AutoRunWebApp>true</AutoRunWebApp>
  <EnableRemoteAccess>true</EnableRemoteAccess>
  <CameraUploadUpgraded>false</CameraUploadUpgraded>
  <CollectionsUpgraded>false</CollectionsUpgraded>
  <EnableCaseSensitiveItemIds>true</EnableCaseSensitiveItemIds>
  <DisableLiveTvChannelUserDataName>false</DisableLiveTvChannelUserDataName>
  <PreferredMetadataLanguage>en</PreferredMetadataLanguage>
  <MetadataCountryCode>US</MetadataCountryCode>
  <SortReplaceCharacters>
    <string>.</string>
    <string>+</string>
    <string>%</string>
  </SortReplaceCharacters>
  <SortRemoveCharacters>
    <string>,</string>
    <string>&amp;</string>
    <string>-</string>
    <string>{</string>
    <string>}</string>
    <string>'</string>
  </SortRemoveCharacters>
  <SortRemoveWords>
    <string>the</string>
    <string>a</string>
    <string>an</string>
  </SortRemoveWords>
  <MinResumePct>5</MinResumePct>
  <MaxResumePct>90</MaxResumePct>
  <MinResumeDurationSeconds>300</MinResumeDurationSeconds>
  <LibraryMonitorDelay>60</LibraryMonitorDelay>
  <EnableDashboardResponseCaching>true</EnableDashboardResponseCaching>
  <ImageSavingConvention>Compatible</ImageSavingConvention>
  <MetadataOptions>
    <MetadataOptions>
      <ItemType>Book</ItemType>
      <DisabledMetadataSavers />
      <LocalMetadataReaderOrder />
      <DisabledMetadataFetchers />
      <MetadataFetcherOrder />
      <DisabledImageFetchers />
      <ImageFetcherOrder />
    </MetadataOptions>
    <MetadataOptions>
      <ItemType>Movie</ItemType>
      <DisabledMetadataSavers />
      <LocalMetadataReaderOrder />
      <DisabledMetadataFetchers />
      <MetadataFetcherOrder />
      <DisabledImageFetchers />
      <ImageFetcherOrder />
    </MetadataOptions>
    <MetadataOptions>
      <ItemType>MusicVideo</ItemType>
      <DisabledMetadataSavers />
      <LocalMetadataReaderOrder />
      <DisabledMetadataFetchers>
        <string>The Open Movie Database</string>
      </DisabledMetadataFetchers>
      <MetadataFetcherOrder />
      <DisabledImageFetchers>
        <string>The Open Movie Database</string>
        <string>FanArt</string>
      </DisabledImageFetchers>
      <ImageFetcherOrder />
    </MetadataOptions>
    <MetadataOptions>
      <ItemType>Series</ItemType>
      <DisabledMetadataSavers />
      <LocalMetadataReaderOrder />
      <DisabledMetadataFetchers>
        <string>TheMovieDb</string>
      </DisabledMetadataFetchers>
      <MetadataFetcherOrder />
      <DisabledImageFetchers>
        <string>TheMovieDb</string>
      </DisabledImageFetchers>
      <ImageFetcherOrder />
    </MetadataOptions>
    <MetadataOptions>
      <ItemType>MusicAlbum</ItemType>
      <DisabledMetadataSavers />
      <LocalMetadataReaderOrder />
      <DisabledMetadataFetchers>
        <string>TheAudioDB</string>
      </DisabledMetadataFetchers>
      <MetadataFetcherOrder />
      <DisabledImageFetchers />
      <ImageFetcherOrder />
    </MetadataOptions>
    <MetadataOptions>
      <ItemType>MusicArtist</ItemType>
      <DisabledMetadataSavers />
      <LocalMetadataReaderOrder />
      <DisabledMetadataFetchers>
        <string>TheAudioDB</string>
      </DisabledMetadataFetchers>
      <MetadataFetcherOrder />
      <DisabledImageFetchers />
      <ImageFetcherOrder />
    </MetadataOptions>
    <MetadataOptions>
      <ItemType>BoxSet</ItemType>
      <DisabledMetadataSavers />
      <LocalMetadataReaderOrder />
      <DisabledMetadataFetchers />
      <MetadataFetcherOrder />
      <DisabledImageFetchers />
      <ImageFetcherOrder />
    </MetadataOptions>
    <MetadataOptions>
      <ItemType>Season</ItemType>
      <DisabledMetadataSavers />
      <LocalMetadataReaderOrder />
      <DisabledMetadataFetchers>
        <string>TheMovieDb</string>
      </DisabledMetadataFetchers>
      <MetadataFetcherOrder />
      <DisabledImageFetchers>
        <string>FanArt</string>
      </DisabledImageFetchers>
      <ImageFetcherOrder />
    </MetadataOptions>
    <MetadataOptions>
      <ItemType>Episode</ItemType>
      <DisabledMetadataSavers />
      <LocalMetadataReaderOrder />
      <DisabledMetadataFetchers>
        <string>The Open Movie Database</string>
        <string>TheMovieDb</string>
      </DisabledMetadataFetchers>
      <MetadataFetcherOrder />
      <DisabledImageFetchers>
        <string>The Open Movie Database</string>
        <string>TheMovieDb</string>
      </DisabledImageFetchers>
      <ImageFetcherOrder />
    </MetadataOptions>
  </MetadataOptions>
  <EnableAutomaticRestart>true</EnableAutomaticRestart>
  <SkipDeserializationForBasicTypes>false</SkipDeserializationForBasicTypes>
  <WanDdns>https://${ip_address}:${app_port_https}</WanDdns>
  <UICulture>en-US</UICulture>
  <SaveMetadataHidden>false</SaveMetadataHidden>
  <ContentTypes />
  <RemoteClientBitrateLimit>0</RemoteClientBitrateLimit>
  <EnableFolderView>false</EnableFolderView>
  <EnableGroupingIntoCollections>false</EnableGroupingIntoCollections>
  <DisplaySpecialsWithinSeasons>true</DisplaySpecialsWithinSeasons>
  <LocalNetworkSubnets />
  <LocalNetworkAddresses>
    <string>0.0.0.0</string>
  </LocalNetworkAddresses>
  <CodecsUsed />
  <IgnoreVirtualInterfaces>false</IgnoreVirtualInterfaces>
  <EnableExternalContentInSuggestions>true</EnableExternalContentInSuggestions>
  <RequireHttps>false</RequireHttps>
  <IsBehindProxy>false</IsBehindProxy>
  <EnableNewOmdbSupport>false</EnableNewOmdbSupport>
  <RemoteIPFilter />
  <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>
  <ImageExtractionTimeoutMs>0</ImageExtractionTimeoutMs>
  <PathSubstitutions />
  <EnableSimpleArtistDetection>true</EnableSimpleArtistDetection>
  <UninstalledPlugins />
</ServerConfiguration>
CONFIG

# Create the service file that will start and stop jellyfin.
cat >"/etc/systemd/system/jellyfin.service" <<-SERVICE
[Unit]
Description=Jellyfin
After=network.target
[Service]
User=${username}
Group=${username}
UMask=002
Type=simple
WorkingDirectory=/home/${username}/.jellyfin
ExecStart=/home/${username}/.jellyfin/jellyfin -d /home/${username}/.config/Jellyfin
TimeoutStopSec=20
KillMode=process
Restart=always
RestartSec=2
[Install]
WantedBy=multi-user.target
SERVICE

# If DLNA port already in use disable DLNA
if lsof -Pi :1900 -t >/dev/null; then
  cat >"/home/${username}/.config/Jellyfin/config/dlna.xml" <<-CONFIG
<?xml version="1.0"?>
<DlnaOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <EnablePlayTo>false</EnablePlayTo>
  <EnableServer>false</EnableServer>
  <EnableDebugLog>false</EnableDebugLog>
  <BlastAliveMessages>true</BlastAliveMessages>
  <SendOnlyMatchedHost>true</SendOnlyMatchedHost>
  <ClientDiscoveryIntervalSeconds>60</ClientDiscoveryIntervalSeconds>
  <BlastAliveMessageIntervalSeconds>1800</BlastAliveMessageIntervalSeconds>
</DlnaOptions>
CONFIG
fi

# Configure the nginx proxypass using positional parameters.
if [[ -f /install/.nginx.lock ]]; then
  bash "/usr/local/bin/swizzin/nginx/jellyfin.sh" "${app_port_http}" "${app_port_https}"
  service nginx reload
fi
#
chown "${username}.${username}" -R "/home/${username}/.jellyfin"
chown "${username}.${username}" -R "/home/${username}/.config"
chown "${username}.${username}" "/home/${username}/.ssl/${username}-self-signed.pfx"
#
# Start the jellyfin service.
systemctl daemon-reload
systemctl enable --now "jellyfin.service" >>/dev/null 2>&1
#
# This file is created after installation to prevent reinstalling. You will need to remove the app first which deletes this file.
touch "/install/.jellyfin.lock"
#
# A helpful echo to the terminal.
echo -e "\nThe Jellyfin installation has completed\n"
#
if [[ ! -f /install/.nginx.lock ]]; then
  echo -e "Jellyfin is available at: https://${ip_address}:${app_port_https}\n"
else
  echo -e "Jellyfin is now available in the panel\n"
fi
#
exit

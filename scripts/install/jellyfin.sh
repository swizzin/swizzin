#!/usr/bin/env bash
#
# authors: liara userdocs
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
########
######## Variables Start
########
#
# Get our main user credentials.
username="$(cat /root/.master.info | cut -d: -f1)"
password="$(cat /root/.master.info | cut -d: -f2)"
#
# This will generate random ports for the script to use with applications between the range 10001 to 32001.
app_port_http="$(shuf -i 10001-32001 -n 1)" && while [[ "$(ss -ln | grep -co ''"${app_port_http}"'')" -ge "1" ]]; do app_port_http="$(shuf -i 10001-32001 -n 1)"; done
app_port_https="$(shuf -i 10001-32001 -n 1)" && while [[ "$(ss -ln | grep -co ''"${app_port_https}"'')" -ge "1" ]]; do app_port_https="$(shuf -i 10001-32001 -n 1)"; done
#
# Get our exertnal IP 4 address and set it as a variable.
ip_address="$(curl -s4 icanhazip.com)"
#
# Define the location where we want the application installed
install_dir="/opt/jellyfin"
#
# Define the location where we want ffmpeg installed.
install_ffmpeg="/opt/ffmpeg"
#
# Set an installation temporay directory.
install_tmp="/tmp/jellyfin"
#
########
######## Variables End
########
#
########
######## Application script starts.
########
#
# Source the global functions we require for this script.
. /etc/swizzin/sources/functions/ssl
#
# Generate the ssl certificates using the sourced function.
create_self_ssl "${username}"
#
# Generate our mono specific ssl cert from the default certs created using the ssl function
openssl pkcs12 -export -nodes -out "/home/${username}/.ssl/${username}-self-signed.pfx" -inkey "/home/${username}/.ssl/${username}-self-signed.key" -in "/home/${username}/.ssl/${username}-self-signed.crt" -passout pass:
#
# Create the required directories for this application.
mkdir -p "$install_dir"
mkdir -p "$install_ffmpeg"
mkdir -p "$install_tmp"
mkdir -p "/home/${username}/.config/Jellyfin/config"
#
# Download and extract the files to the defined location.
baseurl=$(curl -s https://repo.jellyfin.org/releases/server/linux/stable/ | grep -Po "href=[\'\"]\K.*?(?=['\"])" | grep combined | grep -v sha256)
wget -qO "$install_tmp/jellyfin.tar.gz" "https://repo.jellyfin.org/releases/server/linux/stable/${baseurl}" > /dev/null 2>&1
#wget -qO "$install_tmp/jellyfin.tar.gz" "$(curl -s https://api.github.com/repos/jellyfin/jellyfin/releases/latest | grep -Po 'ht(.*)linux-amd64(.*)gz')" > /dev/null 2>&1
tar -xvzf "$install_tmp/jellyfin.tar.gz" --strip-components=2 -C "$install_dir" > /dev/null 2>&1
#
# Download the FFmpeg prebuilt binary to the installation temporary directory
wget -qO "$install_tmp/ffmpeg.tar.xz" "https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
#
# Get the top level dir of the archive so we don't need to guess the dir name in future commands
ffmpeg_dir_name="$(tar tf "$install_tmp/ffmpeg.tar.xz" | head -1 | cut -f1 -d"/")"
#
# Extract the archive to the to the installation temporary directory
tar xf "$install_tmp/ffmpeg.tar.xz" -C "$install_tmp"
#
# Removes files we don't need before copying to the ffmpeg installation directory.
rm -rf "$install_tmp/$ffmpeg_dir_name"/{manpages,model,GPLv3.txt,readme.txt}
#
# Copy the required binaries to the ffmpeg installation folder.
cp "$install_tmp/$ffmpeg_dir_name"/* "$install_ffmpeg"
#
# Set the correct permissions
chmod -R 700 "$install_ffmpeg"
#
# Removes the installation temporary folder as we no longer need it.
rm -rf "$install_tmp" > /dev/null 2>&1
#
## Create the configuration files
#
# Create the encoding.xml so that we can define the custom ffmpeg provided.
cat > "/home/${username}/.config/Jellyfin/config/encoding.xml" <<-CONFIG
<?xml version="1.0"?>
<EncodingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <TranscodingTempPath>/home/${username}/.config/Jellyfin/transcoding-temp</TranscodingTempPath>
  <EncoderAppPath>$install_ffmpeg/ffmpeg</EncoderAppPath>
  <EncoderAppPathDisplay>$install_ffmpeg/ffmpeg</EncoderAppPathDisplay>
</EncodingOptions>
CONFIG
#
# Create the dnla.xml so that we can Disable DNLA
cat > "/home/${username}/.config/Jellyfin/config/dlna.xml" <<-CONFIG
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
cat > "/home/${username}/.config/Jellyfin/config/system.xml" <<-CONFIG
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
      <DisabledImageFetchers />
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
  <BaseUrl />
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
#
# Create the service file that will start and stop jellyfin.
cat > "/etc/systemd/system/jellyfin.service" <<-SERVICE
[Unit]
Description=Jellyfin
After=network.target

[Service]
User=${username}
Group=${username}
UMask=002

Type=simple
WorkingDirectory=$install_dir
ExecStart=$install_dir/jellyfin -d /home/${username}/.config/Jellyfin
TimeoutStopSec=20
KillMode=process
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
SERVICE
#
# Configure the nginx proxypass using positional parameters.
if [[ -f /install/.nginx.lock ]]; then
    bash "/usr/local/bin/swizzin/nginx/jellyfin.sh" "${app_port_http}" "${app_port_https}"
    systemctl reload nginx
fi
#
# Set the correct and required permissions of any directories we created or modified.
chown "${username}.${username}" -R "$install_dir"
chown "${username}.${username}" -R "$install_ffmpeg"
chown "${username}.${username}" -R "/home/${username}/.config"
chown "${username}.${username}" -R "/home/${username}/.ssl"
#
# Enable and start the jellyfin service.
systemctl daemon-reload
systemctl enable --now "jellyfin.service" >> /dev/null 2>&1
#
# This file is created after installation to prevent reinstalling. You will need to remove the app first which deletes this file.
touch "/install/.jellyfin.lock"
#
# A helpful echo to the terminal.
echo -e "\nThe Jellyfin installation has completed\n"
#
if [[ ! -f /install/.nginx.lock ]]; then
    echo -e "Jellyfin is available at: https://$(curl -s4 icanhazip.com):${app_port_https}\n"
else
    echo -e "Jellyfin is now available in the panel\n"
    echo -e "Please visit https://$ip_address/jellyfin\n"
fi
#
exit
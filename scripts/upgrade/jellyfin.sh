#!/usr/bin/env bash
#
# authors: liara userdocs
#
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
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
if [[ ! -f /install/.jellyfin.lock ]]; then
  echo "Jellyfin doesn't appear to be installed. What do you hope to accomplish by running this script?"
  exit 1
fi
#
# Stop the jellyfin service
systemctl stop jellyfin
#
# Create the required directories for this application.
mkdir -p "$install_dir"
mkdir -p "$install_ffmpeg"
mkdir -p "$install_tmp"
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
chown "${username}.${username}" -R "$install_dir"
chown "${username}.${username}" -R "$install_ffmpeg"
#
systemctl start jellyfin
#
echo -e "\nJellyfin upgrade completed and service restarted\n"
#
echo -e "Please visit https://$ip_address/jellyfin\n"
#
exit

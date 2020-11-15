#!/bin/bash

#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
master=$(_get_master_username)
codename=$(lsb_release -cs)
distribution=$(lsb_release -is)

airsonicdir="/opt/airsonic" #Where to install airosnic
airsonicusr="airsonic"      #Who to run airsonic as

case $codename in
	"buster")
		echo_progress_start "Adding adoptopenjdk repository"
		apt_install software-properties-common
		wget -qO- https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public | apt-key --keyring /etc/apt/trusted.gpg.d/adoptopenjdk.gpg add - >> "${log}" 2>&1
		add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ >> "${log}" 2>&1
		echo_progress_done "adoptopenjdk repos enabled"
		apt_update
		apt_install adoptopenjdk-8-hotspot
		;;
	*)
		apt_install openjdk-8-jre
		;;
esac

echo_progress_start "Downloading Airsonic binary"
mkdir /opt/airsonic -p
# TODO make dynamic
dlurl=$(curl -s https://api.github.com/repos/airsonic/airsonic/releases/latest | grep "browser_download_url" | grep "airsonic.war" | head -1 | cut -d\" -f 4)
wget "$dlurl" -O /opt/airsonic/airsonic.war >> "$log" 2>&1
useradd $airsonicusr --system -d "$airsonicdir" >> "$log" 2>&1
usermod -a -G "$master" $airsonicusr
sudo chown -R $airsonicusr:$airsonicusr $airsonicdir
echo_progress_done "Binary DL'd"

echo_progress_start "Setting up systemd service"
wget https://raw.githubusercontent.com/airsonic/airsonic/master/contrib/airsonic.service -O /etc/systemd/system/airsonic.service >> "$log" 2>&1
sed -i 's|/var/airsonic|/opt/airsonic|g' /etc/systemd/system/airsonic.service
sed -i 's|PORT=8080|PORT=8185|g' /etc/systemd/system/airsonic.service

defconfdir="/etc/sysconfig"
if [[ $distribution == "Debian" ]]; then
	defconfdir="/etc/defaults"
fi
wget https://raw.githubusercontent.com/airsonic/airsonic/master/contrib/airsonic-systemd-env -O "${defconfdir}"/airsonic >> "$log" 2>&1

systemctl daemon-reload -q
echo_progress_done "Service installed"

if [[ -f /install/.nginx.lock ]]; then
	echo_progress_start "Configuring nginx"
	bash /usr/local/bin/swizzin/nginx/airsonic.sh
	systemctl reload nginx
	echo_progress_done
fi

echo_progress_start "Enabling and starting Airsonic"
systemctl -q enable airsonic --now
echo_progress_done

echo_success "Airsonic installed"
echo_warn "Continue the set up in the browser and change the username and password."

if [[ -f /install/.subsonic.lock ]]; then
	echo_info "If you would like to perform a migration, please see see the following article"
	echo_docs "applications/airsonic#migrating-from-subsonic"
fi
touch /install/.airsonic.lock

#!/bin/bash
#
# ZNC Installer
#
# Originally written for QuickBox.io by liara
#
# QuickBox Copyright (C) 2017 QuickBox.io
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

DISTRO=$(lsb_release -is)
CODENAME=$(lsb_release -cs)
#shellcheck source=sources/functions/letsencrypt
. /etc/swizzin/sources/functions/letsencrypt

echo_progress_start "Creating system user for znc"
useradd znc -m -s /bin/bash
passwd znc -l >> ${log} 2>&1
echo_progress_done

if [[ $DISTRO == Debian ]]; then
    #shellcheck source=sources/functions/backports
    . /etc/swizzin/sources/functions/backports
    check_debian_backports
    set_packages_to_backports znc
    apt_update
fi
apt_install znc
#sudo -u znc crontab -l | echo -e "*/10 * * * * /usr/bin/znc >/dev/null 2>&1\n@reboot /usr/bin/znc >/dev/null 2>&1" | crontab -u znc - > /dev/null 2>&1
echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/znc.service << ZNC
[Unit]
Description=ZNC, an advanced IRC bouncer
After=network-online.target
     
[Service]
ExecStart=/usr/bin/znc -f
User=znc
Restart=always
     
[Install]
WantedBy=multi-user.target
ZNC
systemctl enable -q znc
echo_progress_done

echo_warn "ZNC configuration will now run. Please answer the following prompts"
sleep 5
sudo -H -u znc znc --makeconf
killall -u znc znc > /dev/null 2>&1
sleep 1

# Check for LE cert, and copy it if available.
if [[ -f /install/nginx.lock ]]; then
    le_znc_hook
fi

systemctl start znc
echo "$(grep Port /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" > /install/.znc.lock
echo "$(grep SSL /home/znc/.znc/configs/znc.conf | sed -e 's/^[ \t]*//')" >> /install/.znc.lock
echo_success "ZNC installed"

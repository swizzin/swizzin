#!/usr/bin/env bash
# Remove script for Calibre-Web Automated
set -euo pipefail
CWA_USER="cwa"
CWA_HOME="/opt/cwa-automated"

. /etc/swizzin/sources/functions/color_echo || true

echo_progress_start "Removing Calibre-Web Automated"

systemctl stop cwa-automated.service || true
systemctl disable cwa-automated.service || true
rm -rf "$CWA_HOME"
if id "$CWA_USER" &> /dev/null; then
    userdel --remove "$CWA_USER" || true
fi
rm -f /etc/nginx/sites-enabled/cwa-automated.conf /etc/nginx/sites-available/cwa-automated.conf
systemctl reload nginx || true
rm -f /install/cwa-automated.lock || true
echo_progress_done "Removed Calibre-Web Automated"

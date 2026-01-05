#!/usr/bin/env bash
# Update script for Calibre-Web Automated
set -euo pipefail
CWA_USER="cwa"
CWA_HOME="/opt/cwa-automated"
CWA_BRANCH="${CWA_BRANCH:-master}"

. /etc/swizzin/sources/functions/color_echo || true

echo_progress_start "Updating Calibre-Web Automated"

if [ -d "$CWA_HOME" ]; then
    sudo -u "$CWA_USER" git -C "$CWA_HOME" fetch --all
    sudo -u "$CWA_USER" git -C "$CWA_HOME" reset --hard "origin/$CWA_BRANCH"
    # Update Python deps if requirements present
    if [ -f "$CWA_HOME/requirements.txt" ]; then
        "$CWA_HOME/venv/bin/pip" install -r "$CWA_HOME/requirements.txt"
    fi
    systemctl restart cwa-automated.service || true
    echo_progress_done "Calibre-Web Automated updated"
else
    echo_error "Installation not found at $CWA_HOME"
    exit 1
fi

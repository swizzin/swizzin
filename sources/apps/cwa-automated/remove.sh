#!/usr/bin/env bash
# Remove script for Calibre-Web Automated
set -euo pipefail
IFS=$'\n\t'
CWA_USER="cwa"
CWA_HOME="/opt/cwa-automated"
LOCK_FILE="/install/cwa-automated.lock"

# shellcheck disable=SC1091
. /etc/swizzin/sources/functions/color_echo || true

if command -v echo_progress_start &>/dev/null; then
    echo_progress_start "Removing Calibre-Web Automated"
fi

# Stop and disable the service if the unit exists
if [ -f /etc/systemd/system/cwa-automated.service ] || systemctl list-units --full -all | grep -q "cwa-automated.service"; then
    systemctl stop cwa-automated.service || true
    systemctl disable cwa-automated.service || true
fi

rm -rf "$CWA_HOME" || true

if id "$CWA_USER" &>/dev/null; then
    userdel --remove "$CWA_USER" || true
fi

rm -f /etc/nginx/sites-enabled/cwa-automated.conf /etc/nginx/sites-available/cwa-automated.conf || true

if [ -f /etc/systemd/system/cwa-automated.service ]; then
    rm -f /etc/systemd/system/cwa-automated.service || true
    systemctl daemon-reload || true
fi

# Reload nginx only if present and config test passes
if command -v nginx &>/dev/null; then
    if nginx -t >/dev/null 2>&1; then
        systemctl reload nginx || true
    fi
fi

rm -f "$LOCK_FILE" || true

if command -v echo_progress_done &>/dev/null; then
    echo_progress_done "Removed Calibre-Web Automated"
fi

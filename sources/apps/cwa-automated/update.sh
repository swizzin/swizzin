#!/usr/bin/env bash
# Update script for Calibre-Web Automated
set -euo pipefail
IFS=$'\n\t'
CWA_USER="cwa"
CWA_HOME="/opt/cwa-automated"
CWA_BRANCH="${CWA_BRANCH:-master}"

# shellcheck disable=SC1091
. /etc/swizzin/sources/functions/color_echo || true

if command -v echo_progress_start &>/dev/null; then
    echo_progress_start "Updating Calibre-Web Automated"
fi

if [ -d "$CWA_HOME" ]; then
    # Update the repository as the service user
    runuser -u "$CWA_USER" -- git -C "$CWA_HOME" fetch --all
    runuser -u "$CWA_USER" -- git -C "$CWA_HOME" reset --hard "origin/$CWA_BRANCH"

    # Update Python deps if requirements present
    if [ -f "$CWA_HOME/requirements.txt" ]; then
        if [ -x "${CWA_HOME}/venv/bin/pip" ]; then
            "$CWA_HOME/venv/bin/pip" install --upgrade pip --no-cache-dir || true
            "$CWA_HOME/venv/bin/pip" install -r "$CWA_HOME/requirements.txt" --no-cache-dir || true
        fi
    fi

    if [ -f /etc/systemd/system/cwa-automated.service ] || systemctl list-units --full -all | grep -q "cwa-automated.service"; then
        systemctl restart cwa-automated.service || true
    fi

    if command -v echo_progress_done &>/dev/null; then
        echo_progress_done "Calibre-Web Automated updated"
    fi
else
    echo_error "Installation not found at $CWA_HOME"
    exit 1
fi

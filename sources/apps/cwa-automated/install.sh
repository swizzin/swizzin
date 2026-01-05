#!/usr/bin/env bash
# Install script for Calibre-Web Automated (swizzin package)
# Conforms to CONTRIBUTING.md: installs under /opt, uses systemd service, supports unattended installs via env vars

set -euo pipefail

# Defaults (can be overridden via environment variables)
CWA_USER="cwa"
CWA_HOME="/opt/cwa-automated"
CWA_REPO="${CWA_REPO:-https://github.com/janeczku/calibre-web.git}"
CWA_BRANCH="${CWA_BRANCH:-master}"
PYTHON_BIN="python3"
VENV_PATH="$CWA_HOME/venv"
LOG="/root/logs/swizzin.log"

# Use exported helper functions where available
# shellcheck disable=SC1091
. /etc/swizzin/sources/functions/color_echo || true

echo_progress_start "Installing Calibre-Web Automated"

ensure_user() {
    if ! id "$CWA_USER" &> /dev/null; then
        echo_info "Creating user $CWA_USER"
        useradd --system --home "$CWA_HOME" --shell /usr/sbin/nologin "$CWA_USER"
    fi
}

install_prereqs() {
    echo_info "Installing system packages"
    # Use apt_install from sources/functions if available
    if command -v apt_install &> /dev/null; then
        apt_install --recommends git "$PYTHON_BIN"-venv "$PYTHON_BIN"-dev build-essential
    else
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git "$PYTHON_BIN"-venv "$PYTHON_BIN"-dev build-essential
    fi
}

clone_and_setup() {
    echo_info "Preparing installation directory $CWA_HOME"
    mkdir -p "$CWA_HOME"
    chown "$CWA_USER":"$CWA_USER" "$CWA_HOME"

    echo_info "Cloning repository $CWA_REPO (branch: $CWA_BRANCH)"
    if [ -d "$CWA_HOME/.git" ]; then
        sudo -u "$CWA_USER" git -C "$CWA_HOME" fetch --all
        sudo -u "$CWA_USER" git -C "$CWA_HOME" reset --hard "origin/$CWA_BRANCH"
    else
        sudo -u "$CWA_USER" git clone --depth 1 --branch "$CWA_BRANCH" "$CWA_REPO" "$CWA_HOME"
    fi

    echo_info "Creating Python virtual environment"
    "$PYTHON_BIN" -m venv "$VENV_PATH"
    # shellcheck disable=SC1091
    source "$VENV_PATH/bin/activate"
    if [ -f "$CWA_HOME/requirements.txt" ]; then
        pip install --upgrade pip
        pip install -r "$CWA_HOME/requirements.txt"
    else
        pip install --upgrade pip setuptools
    fi
    deactivate

    chown -R "$CWA_USER":"$CWA_USER" "$CWA_HOME"
}

enable_service() {
    echo_info "Enabling systemd service"
    systemctl daemon-reload || true
    systemctl enable --now cwa-automated.service || true
}

main() {
    ensure_user
    install_prereqs
    clone_and_setup
    enable_service
    echo_progress_done "Calibre-Web Automated installed"
}

main "$@"

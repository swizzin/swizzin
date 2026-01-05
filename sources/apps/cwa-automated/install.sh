#!/usr/bin/env bash
# Install script for Calibre-Web Automated (swizzin package)
# Conforms to CONTRIBUTING.md: installs under /opt, uses systemd service, supports unattended installs via env vars

set -euo pipefail
IFS=$'\n\t'

# Defaults (can be overridden via environment variables)
CWA_USER="cwa"
CWA_HOME="/opt/cwa-automated"
CWA_REPO="${CWA_REPO:-https://github.com/janeczku/calibre-web.git}"
CWA_BRANCH="${CWA_BRANCH:-master}"
PYTHON_BIN="python3"
VENV_PATH="$CWA_HOME/venv"
LOG="/root/logs/swizzin.log"
SERVICE_SRC="/etc/swizzin/sources/services/cwa-automated.service"
NGINX_SRC="/etc/swizzin/sources/nginx/cwa-automated.conf"
LOCK_FILE="/install/cwa-automated.lock"

# Use exported helper functions where available
# shellcheck disable=SC1091
. /etc/swizzin/sources/functions/color_echo || true

# Helpers
log() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*" | tee -a "$LOG"
}

# Start progress if helper exists
if command -v echo_progress_start &>/dev/null; then
    echo_progress_start "Installing Calibre-Web Automated"
fi

ensure_user() {
    if ! id "$CWA_USER" &>/dev/null; then
        echo_info "Creating user $CWA_USER"
        useradd --system --no-create-home -d "$CWA_HOME" --shell /usr/sbin/nologin "$CWA_USER"
    fi
    # Ensure installation directory exists and is owned by the service user for repo operations
    mkdir -p "$CWA_HOME"
    chown "$CWA_USER":"$CWA_USER" "$CWA_HOME"
    chmod 755 "$CWA_HOME"
}

install_prereqs() {
    echo_info "Installing system packages"
    # Use apt_install from sources/functions if available
    if command -v apt_install &>/dev/null; then
        apt_install --recommends git "$PYTHON_BIN"-venv "$PYTHON_BIN"-dev build-essential
    else
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git "$PYTHON_BIN"-venv "$PYTHON_BIN"-dev build-essential
    fi
}

clone_and_setup() {
    echo_info "Preparing installation directory $CWA_HOME"

    # Clone or update repository as the service user
    if [ -d "$CWA_HOME/.git" ]; then
        runuser -u "$CWA_USER" -- git -C "$CWA_HOME" fetch --all
        runuser -u "$CWA_USER" -- git -C "$CWA_HOME" reset --hard "origin/$CWA_BRANCH"
    else
        runuser -u "$CWA_USER" -- git clone --depth 1 --branch "$CWA_BRANCH" "$CWA_REPO" "$CWA_HOME"
    fi

    echo_info "Creating Python virtual environment"
    "$PYTHON_BIN" -m venv "$VENV_PATH"

    if [ -f "$CWA_HOME/requirements.txt" ]; then
        "$VENV_PATH/bin/pip" install --upgrade pip --no-cache-dir
        "$VENV_PATH/bin/pip" install -r "$CWA_HOME/requirements.txt" --no-cache-dir
    else
        "$VENV_PATH/bin/pip" install --upgrade pip setuptools --no-cache-dir
    fi

    chown -R "$CWA_USER":"$CWA_USER" "$CWA_HOME"
}

install_service_and_nginx() {
    echo_info "Installing systemd unit and nginx site (if present)"

    if [ -f "$SERVICE_SRC" ]; then
        mkdir -p /etc/systemd/system
        install -m 644 "$SERVICE_SRC" /etc/systemd/system/cwa-automated.service
    else
        echo_warn "Service source $SERVICE_SRC not found in /etc/swizzin. The unit will not be installed."
    fi

    if [ -f "$NGINX_SRC" ]; then
        mkdir -p /etc/nginx/sites-available
        mkdir -p /etc/nginx/sites-enabled
        install -m 644 "$NGINX_SRC" /etc/nginx/sites-available/cwa-automated.conf
        ln -sf /etc/nginx/sites-available/cwa-automated.conf /etc/nginx/sites-enabled/cwa-automated.conf
    else
        echo_warn "Nginx source $NGINX_SRC not found in /etc/swizzin. The nginx site will not be installed."
    fi

    # Reload systemd and enable/start service if present
    if [ -f /etc/systemd/system/cwa-automated.service ]; then
        systemctl daemon-reload || true
        systemctl enable --now cwa-automated.service || true
    fi

    # Test and reload nginx if available
    if command -v nginx &>/dev/null; then
        if nginx -t >/dev/null 2>&1; then
            systemctl reload nginx || echo_warn "nginx reload failed"
        else
            echo_warn "nginx config test failed; not reloading nginx"
        fi
    fi
}

write_lock() {
    mkdir -p /install
    cat >"$LOCK_FILE" <<EOF
installed: true
path: $CWA_HOME
date: $(date -Iseconds)
repo: $CWA_REPO
branch: $CWA_BRANCH
EOF
    chmod 644 "$LOCK_FILE"
}

main() {
    log "Starting installation"
    ensure_user
    install_prereqs
    clone_and_setup
    install_service_and_nginx
    write_lock
    log "Calibre-Web Automated installed"
    if command -v echo_progress_done &>/dev/null; then
        echo_progress_done "Calibre-Web Automated installed"
    fi
}

main "$@"

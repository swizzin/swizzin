#!/usr/bin/env bash
set -euo pipefail
# Run a full box-style test for calibrewebautomated (install -> verify -> cleanup)

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BACKUP_DIR="/tmp/swizzin-test-backup-$$"
DST_BIN=/usr/local/bin/swizzin
DST_ETC=/etc/swizzin
LOG=/root/logs/install.log
TEMP_INSTALL_LOCK=/install/.calibrewebautomated.lock

function ensure_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Re-run with sudo." >&2
        exit 1
    fi
}

function backup() {
    mkdir -p "$BACKUP_DIR"
    if [[ -d "$DST_BIN" ]]; then
        echo "Backing up $DST_BIN -> $BACKUP_DIR/bin"
        mv "$DST_BIN" "$BACKUP_DIR/bin"
    fi
    if [[ -d "$DST_ETC" ]]; then
        echo "Backing up $DST_ETC -> $BACKUP_DIR/etc"
        mv "$DST_ETC" "$BACKUP_DIR/etc"
    fi
}

function deploy() {
    echo "Deploying test files to $DST_BIN and $DST_ETC"
    mkdir -p "$DST_BIN/install" "$DST_BIN/remove" "$DST_BIN/upgrade" "$DST_BIN/nginx"
    mkdir -p "$DST_ETC/scripts/nginx" "$DST_ETC/sources"

    # Copy box script
    install -m 0755 "$REPO_ROOT/scripts/box" "$DST_BIN/box"

    # Copy install/remove/upgrade scripts used for test
    rsync -a "$REPO_ROOT/scripts/install/" "$DST_BIN/install/"
    rsync -a "$REPO_ROOT/scripts/remove/" "$DST_BIN/remove/" || true
    rsync -a "$REPO_ROOT/scripts/upgrade/" "$DST_BIN/upgrade/" || true

    # Copy nginx scripts to /etc/swizzin/scripts/nginx (installers source these)
    rsync -a "$REPO_ROOT/scripts/nginx/" "$DST_ETC/scripts/nginx/"

    # Copy sources (globals, functions)
    rsync -a "$REPO_ROOT/sources/" "$DST_ETC/sources/"

    chmod -R 0755 "$DST_BIN"
}

function prepare_env() {
    mkdir -p "$(dirname "$LOG")"
    touch "$LOG"
    export log="$LOG"
    export CALIBRE_LIBRARY_USER="$(logname 2> /dev/null || echo tester)"
    export CALIBRE_LIBRARY_PATH="/home/$CALIBRE_LIBRARY_USER/Calibre Library"
    mkdir -p /install
}

function run_install() {
    echo "Running box install calibrewebautomated"
    # Use the deployed box script directly
    "$DST_BIN/box" install calibrewebautomated 2>&1 | tee -a "$LOG" || true
}

function verify() {
    echo "Verifying installation artifacts"
    echo "Systemd unit:"
    systemctl status calibrewebautomated.service --no-pager || true
    echo "Last journal lines:"
    journalctl -u calibrewebautomated.service --no-pager -n 50 || true
    echo "HTTP check (localhost:8083):"
    curl -I --max-time 5 http://127.0.0.1:8083 || true
    echo "Files in /opt:/"
    ls -ld /opt/calibrewebautomated || true
}

function cleanup() {
    echo "Removing calibrewebautomated via box remove/clear"
    # Use box to remove if available
    "$DST_BIN/box" clr calibrewebautomated 2>&1 | tee -a "$LOG" || true

    echo "Manual cleanup: stopping service and removing files"
    systemctl stop calibrewebautomated.service || true
    systemctl disable calibrewebautomated.service || true
    rm -f /etc/systemd/system/calibrewebautomated.service || true
    systemctl daemon-reload || true
    userdel -r calibrewebautomated 2> /dev/null || true
    rm -rf /opt/calibrewebautomated /opt/.venv/calibrewebautomated || true
    rm -f /etc/nginx/apps/calibrewebautomated.conf || true
    rm -f /install/.calibrewebautomated.lock || true
    rm -f /usr/local/bin/kepubify || true
}

function restore() {
    echo "Restoring backups"
    # Remove deployed dirs
    rm -rf "$DST_BIN" "$DST_ETC"
    if [[ -d "$BACKUP_DIR/bin" ]]; then
        mv "$BACKUP_DIR/bin" "$DST_BIN"
    fi
    if [[ -d "$BACKUP_DIR/etc" ]]; then
        mv "$BACKUP_DIR/etc" "$DST_ETC"
    fi
    rm -rf "$BACKUP_DIR"
}

function usage() {
    cat << EOF
Usage: sudo bash $0 [--nginx] [--keep]
  --nginx   : create /install/.nginx.lock so nginx conf is applied
  --keep    : keep deployed files in /usr/local/bin/swizzin and /etc/swizzin (no restore)
EOF
    exit 1
}

ensure_root

NGINX_LOCK=false
KEEP=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --nginx)
            NGINX_LOCK=true
            shift
            ;;
        --keep)
            KEEP=true
            shift
            ;;
        -h | --help) usage ;;
        *)
            echo "Unknown arg: $1"
            usage
            ;;
    esac
done

backup
deploy
prepare_env
if $NGINX_LOCK; then
    mkdir -p /install
    touch /install/.nginx.lock
fi

run_install
sleep 5
verify

# Only perform cleanup (stop service / remove installed files) when not keeping deployed files
if ! $KEEP; then
    cleanup
fi

if ! $KEEP; then
    restore
    echo "Test complete — backups restored. Logs: $LOG"
else
    echo "Test complete — deployed files left in place for inspection. Logs: $LOG"
fi

exit 0

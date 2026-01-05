# Calibre-Web Automated (swizzin package)

This package installs Calibre-Web without using Docker. It follows Swizzin guidelines by installing to /opt, creating a systemd unit, and providing an nginx template for reverse-proxying.

Installation (non-interactive):

export CWA_REPO="https://github.com/janeczku/calibre-web.git"
export CWA_BRANCH="master"
sudo bash /etc/swizzin/sources/apps/cwa-automated/install.sh

Notes:
- The installer will create a system user `cwa` and place files in /opt/cwa-automated
- The service unit is `cwa-automated.service` and listens on port 8083 by default
- Configure nginx using `sources/nginx/cwa-automated.conf` as a template
- Logs should be forwarded to the default swizzin logs; installer does not alter /root/logs by default

Uninstall:
sudo bash /etc/swizzin/sources/apps/cwa-automated/remove.sh

Updating:
sudo bash /etc/swizzin/sources/apps/cwa-automated/update.sh

Contributing notes:
- This package intentionally avoids Docker per CONTRIBUTING.md. If you want to include optional Docker tests, open a separate tests-only PR that is not merged into the application package.

- Touch up: Please ensure the upstream repository URL (CWA_REPO) points to the desired fork for Calibre-Web Automated if different from Janeczku's Calibre-Web.

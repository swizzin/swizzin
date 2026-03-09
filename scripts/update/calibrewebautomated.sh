#!/bin/bash

if [[ -f /install/.calibrewebautomated.lock ]]; then
    if grep -q -- "cps.py -f" /etc/systemd/system/calibrewebautomated.service; then
        echo_info "Updating CWA service file"
        sed -i 's/cps.py -f/cps.py/g' /etc/systemd/system/calibrewebautomated.service
        systemctl daemon-reload
    fi
    if ! /opt/.venv/calibrewebautomated/bin/python3 -c "import pkg_resources; pkg_resources.require(open('/opt/calibrewebautomated/requirements.txt',mode='r'))" &> /dev/null; then
        echo_progress_start "Updating Calibre-Web Automated requirements"
        /opt/.venv/calibrewebautomated/bin/pip install -r /opt/calibrewebautomated/requirements.txt
        if systemctl is-enabled calibrewebautomated > /dev/null 2>&1 &&
            [[ "$(tail -n 1 /opt/calibrewebautomated/calibre-web.log | grep -c 'webserver stop (restart=True)')" -eq 1 ]]; then
            systemctl restart calibrewebautomated
        fi
        echo_progress_done
    fi
fi

# Remove the proxy_bind setting from Nginx Conf for CWA.
if [[ -f /etc/nginx/apps/calibrewebautomated.conf ]]; then
    if grep -q "proxy_bind[ \t]\+\$server_addr;" /etc/nginx/apps/calibrewebautomated.conf; then
        echo_log_only "Removing proxy_bind from CWA nginx conf"
        # Find the proxy_bind line, and remove it
        sed -i 's/proxy_bind[[:space:]]\+\\\$server_addr;//g' /etc/nginx/apps/calibrewebautomated.conf
        systemctl reload nginx
    fi
fi

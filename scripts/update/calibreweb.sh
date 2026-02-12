#!/bin/bash

if [[ -f /install/.calibreweb.lock ]]; then
    if grep -q -- "cps.py -f" /etc/systemd/system/calibreweb.service; then
        echo_info "Updating Calibre Web service file"
        sed -i 's/cps.py -f/cps.py/g' /etc/systemd/system/calibreweb.service
        systemctl daemon-reload
    fi

    pip_version=$(/opt/.venv/calibreweb/bin/pip -V | cut -d' ' -f2)
    if dpkg --compare-versions "$pip_version" lt "22.2"; then
        echo_progress_start "Upgrading pip for Calibre Web"
        /opt/.venv/calibreweb/bin/pip install --upgrade pip >> ${log} 2>&1
        echo_progress_done
    fi

    if ! /opt/.venv/calibreweb/bin/pip install -r /opt/calibreweb/requirements.txt --dry-run | grep -q -i would; then
        echo_progress_start "Updating Calibre Web requirements"
        /opt/.venv/calibreweb/bin/pip install -r /opt/calibreweb/requirements.txt >> ${log} 2>&1
        if systemctl is-enabled calibreweb > /dev/null 2>&1 &&
            [[ "$(tail -n 1 /opt/calibreweb/calibre-web.log | grep -c 'webserver stop (restart=True)')" -eq 1 ]]; then
            systemctl restart calibreweb
        fi
        echo_progress_done
    fi

    if [[ -f /etc/nginx/apps/calibreweb.conf ]]; then
        if ! grep -q -- "proxy_buffer_size" /etc/nginx/apps/calibreweb.conf; then
            echo_progress_start "Updating Calibre Web nginx config"
            bash /usr/local/bin/swizzin/nginx/calibreweb.sh
            systemctl reload nginx
            echo_progress_done
        fi
    fi
fi

# Remove the proxy_bind setting from Nginx Conf.
if [[ -f /etc/nginx/apps/calibreweb.conf ]]; then
    if grep -q "proxy_bind[ \t]\+\$server_addr;" /etc/nginx/apps/calibreweb.conf; then
        echo_log_only "Removing proxy_bind from CalibreWeb nginx conf"
        # Find the proxy_bind line, and remove it
        sed -i 's/proxy_bind[[:space:]]\+\\\$server_addr;//g' /etc/nginx/apps/calibreweb.conf
        systemctl reload nginx
    fi
fi

# !/bin/bash
# Lidarr updater script 

if [[ -f /install/.lidarr.lock ]]; then
  if grep -q "WorkingDirectory=/home/%I/Lidarr" /etc/systemd/system/lidarr@.service; then
    :
  else
    sed -i 's/WorkingDirectory.*/WorkingDirectory=\/home\/%I\/Lidarr/g' /etc/systemd/system/lidarr@.service
    sleep 1; systemctl daemon-reload
  fi

  if grep -q "proxy_set_header Host" /etc/nginx/apps/lidarr.conf; then
    sed -i "/proxy_set_header Host/d" /etc/nginx/apps/lidarr.conf
    systemctl reload nginx
  fi
fi
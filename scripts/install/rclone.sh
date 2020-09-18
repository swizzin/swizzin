#!/bin/bash
echo "Downloading and installing rclone" 
wget https://rclone.org/install.sh -O /tmp/rcloneinstall.sh >> $ log 2>&1
if ! bash /tmp/rcloneinstall.sh >> $log 2>&1; then
  echo_error "Setup failed"
fi
echo_progress_done "rclone installed"

echo_progress_start "Adding rclone multi-user mount service" 
cat >/etc/systemd/system/rclone@.service<<EOF
[Unit]
Description=rclonemount
After=network.target

[Service]
Type=simple
User=%i
Group=%i
ExecStart=/usr/sbin/rclone mount /home/%i/cloud --allow-non-empty --allow-other --dir-cache-time 10m --max-read-ahead 9G --checkers 32 --contimeout 15s --quiet
ExecStop=/bin/fusermount -u /home/%i/cloud
Restart=on-failure
RestartSec=30
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target

EOF

echo_progress_done "Service file installed"
touch /install/.rclone.lock
echo_success "Rclone installed!" 


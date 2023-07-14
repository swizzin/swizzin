#!/bin/bash
# Scrutiny installer by flying_sausages for Swizzin 2020
# GPLv3 applies

# based on https://github.com/AnalogJ/scrutiny/blob/master/docs/INSTALL_MANUAL.md

scrutinydir="/opt/scrutiny"
webport=8087

_install() {

    case "$(_os_arch)" in
        "amd64") arch='amd64' ;;
        "arm64") arch="arm64" ;;
        "armhf") arch="arm-6" ;;
        *)
            echo_error "Arch not supported"
            exit 1
            ;;
    esac

    mkdir -p "${scrutinydir}"/config
    mkdir -p "${scrutinydir}"/web
    mkdir -p "${scrutinydir}"/bin

    useradd --system scrutiny -d "${scrutinydir}"
    usermod -a -G disk scrutiny

    wget -q https://repos.influxdata.com/influxdata-archive_compat.key
    echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

    apt_update
    apt_install influxdb2 smartmontools

    #shellcheck source=sources/functions/scrutiny
    . /etc/swizzin/sources/functions/scrutiny
    _download_scrutiny

    cat > "${scrutinydir}"/config/scrutiny.yaml << EOF
version: 1

web:
  database:
    # The Scrutiny webapp will create a database for you, however the parent directory must exist.
    location: ${scrutinydir}/config/scrutiny.db
  src:
    frontend:
      # The path to the Scrutiny frontend files (js, css, images) must be specified.
      # We'll populate it with files in the next section
      path: ${scrutinydir}/web
  listen:
    port: $webport
    host: 0.0.0.0
EOF
    # the basepath is set in the nginx install fyi
}

_systemd() {
    echo_progress_start "Installing systemd services"
    cat > /etc/systemd/system/scrutiny-web.service << SYSD
[Unit]
Description=Scrutiny web frontend
Requires=influxdb.service
After=network.target

[Service]
User=scrutiny
ExecStart=${scrutinydir}/bin/scrutiny-web-linux-$arch start --config ${scrutinydir}/config/scrutiny.yaml
Restart=on-abort
TimeoutSec=20

[Install]
WantedBy=multi-user.target
SYSD

    cat > /etc/systemd/system/scrutiny-collector.service << EOF
[Unit]
Description=Runs scrutiny collector
Wants=scrutiny-collector.timer

[Service]
ExecStart=${scrutinydir}/bin/scrutiny-collector-metrics-linux-$arch run --api-endpoint "http://localhost:$webport"
WorkingDirectory=${scrutinydir}

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/scrutiny-collector.timer << EOF
[Unit] 
Description=Run scrutiny-collector every 5 minutes
Requires=scrutiny-collector.service

[Timer]
Unit=scrutiny-collector.service
OnUnitInactiveSec=5min
# RandomizedDelaySec=15min
AccuracySec=1s
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl enable --now -q influxdb
    systemctl daemon-reload
    systemctl enable --now -q scrutiny-web

    # One run for good measure
    sleep 5
    ${scrutinydir}/bin/scrutiny-collector-metrics-linux-$arch run --api-endpoint "http://localhost:$webport" >> $log 2>&1

    systemctl enable --now -q scrutiny-collector.timer
    systemctl enable --now -q scrutiny-collector.service
    echo_progress_done "Scrutiny services started"
}

_nginx() {
    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /etc/swizzin/scripts/nginx/scrutiny.sh
        systemctl reload nginx
        echo_progress_done "Nginx configured"
    fi
}

_install
_systemd
_nginx

touch /install/.scrutiny.lock
echo_success "Scrutiny installed"

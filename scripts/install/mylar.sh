#!/bin/bash
# Brett 2021
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv
#shellcheck source=sources/functions/utils
. /etc/swizzin/sources/functions/utils
app_name="mylar"
if [ -z "$MYLAR_OWNER" ]; then
    if ! MYLAR_OWNER="$(swizdb get "$app_name/owner")"; then
        MYLAR_OWNER="$(_get_master_username)"
        echo_info "Setting ${app_name^} owner = $MYLAR_OWNER"
        swizdb set "$app_name/owner" "$MYLAR_OWNER"
    fi
else
    echo_info "Setting ${app_name^} owner = $MYLAR_OWNER"
    swizdb set "$app_name/owner" "$MYLAR_OWNER"
fi
user="$MYLAR_OWNER"
swiz_configdir="/home/$user/.config"
app_configdir="$swiz_configdir/${app_name^}"
app_configfile="$app_configdir/config.ini"
app_group="$user"
app_port="$(port 7000 11000)"
app_servicefile="$app_name.service"
app_dir="/opt/${app_name^}"
app_binary="${app_name^}"
#Remove any dashes in appname per FS
app_lockname="${app_name//-/}"

if [ ! -d "$swiz_configdir" ]; then
    mkdir -p "$swiz_configdir"
fi
function install_mylar() {
    chown "$user":"$app_group" "$swiz_configdir"
    # deps
    apt_install python3 git
    mkdir -p /opt/.venv/${app_name}
    # pyenv
    pyenv_install
    pyenv_install_version 3.8.1
    pyenv_create_venv 3.8.1 /opt/.venv/${app_name}/
    # mylar
    echo_progress_start "Grabbing the latest Mylar."
    git clone https://github.com/mylar3/mylar3.git $app_dir >> $log 2>&1
    echo_progress_done "Mylar downloaded."
    echo_progress_start "Upgrading pip and installing dependencies."
    /opt/.venv/${app_name}/bin/pip install --upgrade pip >> $log 2>&1
    /opt/.venv/${app_name}/bin/pip install --upgrade pip >> $log 2>&1
    /opt/.venv/${app_name}/bin/pip3 install -r $app_dir/requirements.txt >> $log 2>&1
    echo_progress_done "Upgrading pip and installing dependencies."
    # ownership
    echo_progress_start "Owning the files to $user"
    chown $user:$app_group -R $app_dir
    chown $user:$app_group -R /opt/.venv/${app_name}
    echo_progress_done "$user owns files."
    echo_progress_start "Writing service file."
    cat > /etc/systemd/system/$app_servicefile << MLR
[Unit]
Description=mylarr3 service
After=nginx.service

[Service]
Type=simple
User=$user

ExecStart=/opt/.venv/${app_name}/bin/python $app_binary.py -p $app_port --datadir $app_configdir
WorkingDirectory=$app_dir
Restart=on-failure
TimeoutStopSec=300

[Install]
WantedBy=multi-user.target
MLR
    echo_progress_done "Service file written."
    systemctl enable -q --now ${app_servicefile} || echo_warn "Mylar failed to start."
}
#shellcheck source=scripts/nginx/mylar.sh
. /etc/swizzin/scripts/nginx/mylar.sh
install_mylar
echo_progress_start "Installing nginx config."
mylar_ngx
echo_progress_done "nginx config done."
echo_progress_start "Touching lock file."
touch /install/.${app_lockname}.lock
echo_progress_done "Mylar intalled."

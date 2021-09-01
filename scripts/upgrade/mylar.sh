#!/bin/bash
# Brett 2021
user="$(swizdb get mylar/owner)"
app_name="mylar"
app_group="$user"
app_servicefile="$app_name.service"
app_dir="/opt/${app_name^}"

echo_progress_start "Stopping mylar service."
systemctl stop -q ${app_servicefile}
echo_progress_done "Mylar stopped."
echo_progress_start "Grabbing the latest mylar from git."
git -C /opt/Mylar/ fetch origin >> $log 2>&1
git -C /opt/Mylar/ reset --hard origin/master >> $log 2>&1
echo_progress_done "Grabbed latest mylar."
echo_progress_start "Grabbing requirements.txt"
/opt/.venv/${app_name}/bin/pip3 install -r $app_dir/requirements.txt >> $log 2>&1
echo_progress_done "Requirements satisfied."
echo_progress_start "Fixing ownership"
chown ${user}:${app_group} /opt/Mylar/
chown ${user}:${app_group} /opt/.venv/mylar/
echo_progress_done "Ownership fixed."
echo_progress_start "Starting ${app_servicefile}"
systemctl start -q ${app_servicefile}
echo_progress_done "${app_servicefile} started."
echo_info "Mylar is up to date."

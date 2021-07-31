#!/bin/bash
#
# [swizzin :: Install flexget package]
#
# Script by Aethaeran
# based off liara's install/pyload.sh
#
# Swizzin by liara
#
# swizzin Copyright (C) 2020 swizzin.ltd
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.

# References
# https://flexget.com/InstallWizard/Linux
# https://flexget.com/Daemon
# https://flexget.com/Plugins/Daemon/scheduler
# https://flexget.com/CLI
# https://flexget.com/Cookbook/Jdownloader2
# https://flexget.com/Plugins/qbittorrent
# https://flexget.com/Plugins/nzbget

# TODO: Create a service file. To run the flexget daemon.
# TODO: Should we help the end user set up the scheduler, and other essential plugins?


# TODO: Should we have the functionality of automatically integrating with other installed swizzin packages?

# Import functions
# TODO: Combine imports here.
. /etc/swizzin/sources/functions/pyenv

# Set variables
# TODO: Update these to use swizzin functions, and remove unnecessary ones.
codename=$(lsb_release -cs)
user=$(cut -d: -f1 < /root/.master.info)
password=$(cut -d: -f2 < /root/.master.info)
SALT=$(shuf -zr -n5 -i 0-9 | tr -d '\0')
SALTWORD=${SALT}${password}
SALTWORDHASH=$(echo -n "${SALTWORD}" | shasum -a 1 | awk '{print $1}')
HASH=${SALT}${SALTWORDHASH}
app_name="flexget"

# Create virtualenv
python3_venv "${user}" "$app_name"

# TODO: Install python dependencies
echo_progress_start "Installing python dependencies"
PIP='wheel setuptools<45 pycurl pycrypto tesseract pillow pyOpenSSL js2py feedparser beautifulsoup'
#shellcheck disable=SC2154 disable=SC2086
/opt/.venv/"$app_name"/bin/pip install $PIP >> "${log}" 2>&1
chown -R "${user}:" /opt/.venv/"$app_name"
echo_progress_done

# TODO: Do I need to git clone?
echo_progress_start "Cloning $app_name"
git clone --branch "stable" https://github.com/"$app_name"/"$app_name".git /opt/"$app_name" >> "${log}" 2>&1
echo_progress_done

# TODO: Set up a configuration for each swizzin user.
echo_progress_start "Configuring $app_name"
echo "/opt/$app_name" > /opt/"$app_name"/module/config/configdir

cat > /opt/"$app_name"/"$app_name".conf << PYCONF
version: 1

download - "Download":
        int chunks : "Max connections for one download" = 3
        str interface : "Download interface to bind (ip or Name)" = None
        bool ipv6 : "Allow IPv6" = False
        bool limit_speed : "Limit Download Speed" = False
        int max_downloads : "Max Parallel Downloads" = 3
        int max_speed : "Max Download Speed in kb/s" = -1
        bool skip_existing : "Skip already existing files" = False

downloadTime - "Download Time":
        time end : "End" = 0:00
        time start : "Start" = 0:00

general - "General":
        bool checksum : "Use Checksum" = False
        bool debug_mode : "Debug Mode" = False
        folder download_folder : "Download Folder" = /home/${user}/Downloads
        bool folder_per_package : "Create folder for each package" = True
        en;de;fr;it;es;nl;sv;ru;pl;cs;sr;pt_BR language : "Language" = en
        int min_free_space : "Min Free Space (MB)" = 200
        int renice : "CPU Priority" = 0

log - "Log":
        bool file_log : "File Log" = True
        int log_count : "Count" = 5
        folder log_folder : "Folder" = Logs
        bool log_rotate : "Log Rotate" = True
        int log_size : "Size in kb" = 100

permission - "Permissions":
        bool change_dl : "Change Group and User of Downloads" = False
        bool change_file : "Change file mode of downloads" = False
        bool change_group : "Change group of running process" = False
        bool change_user : "Change user of running process" = False
        str file : "Filemode for Downloads" = 0644
        str folder : "Folder Permission mode" = 0755
        str group : "Groupname" = users
        str user : "Username" = user

proxy - "Proxy":
        str address : "Address" = "localhost"
        password password : "Password" = None
        int port : "Port" = 7070
        bool proxy : "Use Proxy" = False
        http;socks4;socks5 type : "Protocol" = http
        str username : "Username" = None

reconnect - "Reconnect":
        bool activated : "Use Reconnect" = False
        time endTime : "End" = 0:00
        str method : "Method" = None
        time startTime : "Start" = 0:00

remote - "Remote":
        bool activated : "Activated" = False
        ip listenaddr : "Adress" = 0.0.0.0
        bool nolocalauth : "No authentication on local connections" = True
        int port : "Port" = 7227

ssl - "SSL":
        bool activated : "Activated" = False
        file cert : "SSL Certificate" = ssl.crt
        file key : "SSL Key" = ssl.key

webinterface - "Webinterface":
        bool activated : "Activated" = True
        bool basicauth : "Use basic auth" = False
        ip host : "IP" = 0.0.0.0
        bool https : "Use HTTPS" = False
        int port : "Port" = 8000
        str prefix : "Path Prefix" =
        builtin;threaded;fastcgi;lightweight server : "Server" = builtin
        modern;pyplex;classic template : "Template" = modern
PYCONF

echo_progress_done

echo_progress_start "Initializing database"
read < <(
    /opt/.venv/"$app_name"/bin/python2 /opt/"$app_name"/pyLoadCore.py > /dev/null 2>&1 &
    echo $!
) -r
PID=$REPLY
sleep 10
#kill -9 $PID
while kill -0 "$PID" > /dev/null 2>&1; do
    sleep 1
    kill "$PID" > /dev/null 2>&1
done

if [ -f "/opt/$app_name/files.db" ]; then
    sqlite3 /opt/"$app_name"/files.db "\
    INSERT INTO users('name', 'password') \
      VALUES('${user}','${HASH}');\
      "
    echo_progress_done
else
    echo_error "Something went wrong with user setup -- you will be unable to login"
    #TODO maybe exit then?
fi

chown -R "${user}:" /opt/"$app_name"
mkdir -p "/home/${user}/Downloads"
chown "${user}:" "/home/${user}/Downloads"

# TODO: Create mutli-seat service file. Be sure to point to each user configuration separately.
echo_progress_start "Installing systemd service"
cat > /etc/systemd/system/"$app_name".service << FGSD
[Unit]
Description="$app_name"
After=network.target

[Service]
User=${user}
ExecStart=/opt/.venv/"$app_name"/bin/python2 /opt/"$app_name"/pyLoadCore.py --config=/opt/"$app_name"
WorkingDirectory=/opt/"$app_name"

[Install]
WantedBy=multi-user.target
FGSD
echo_progress_done

# TODO: Should I include the web UI or not? It is not recommended by themselves.
if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/"$app_name".sh
    systemctl reload nginx
    echo_progress_done
fi
echo_progress_start "Enabling and starting $app_name services"
systemctl enable -q --now "$app_name".service 2>&1 | tee -a "$log"
echo_progress_done

echo_success "$app_name installed"
touch /install/."$app_name".lock

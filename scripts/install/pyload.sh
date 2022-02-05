#!/bin/bash
#
# [swizzin :: Install pyLoad package]
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
#
codename=$(lsb_release -cs)
user=$(cut -d: -f1 < /root/.master.info)
password=$(cut -d: -f2 < /root/.master.info)
SALT=$(shuf -zr -n5 -i 0-9 | tr -d '\0')
SALTWORD=${SALT}${password}
SALTWORDHASH=$(echo -n ${SALTWORD} | shasum -a 1 | awk '{print $1}')
HASH=${SALT}${SALTWORDHASH}
#shellcheck source=sources/functions/pyenv
. /etc/swizzin/sources/functions/pyenv

if [[ $codename =~ ("stretch"|"buster"|"bionic") ]]; then
    LIST='tesseract-ocr gocr rhino python2.7-dev python-pip python-virtualenv virtualenv libcurl4-openssl-dev sqlite3'
else
    LIST='tesseract-ocr gocr rhino libcurl4-openssl-dev python2.7-dev sqlite3'
fi

if [[ $(_os_arch) =~ "arm" ]]; then
    LIST+=' libffi-dev'
fi

apt_install $LIST

if [[ ! $codename =~ ("stretch"|"buster"|"bionic") ]]; then
    python_getpip
fi

python2_venv ${user} pyload

echo_progress_start "Installing python dependencies"
PIP='wheel setuptools<45 pycurl pycrypto tesseract pillow pyOpenSSL js2py feedparser beautifulsoup'
/opt/.venv/pyload/bin/pip install $PIP >> "${log}" 2>&1
chown -R ${user}: /opt/.venv/pyload
echo_progress_done

echo_progress_start "Cloning pyLoad"
git clone --branch "stable" https://github.com/pyload/pyload.git /opt/pyload >> "${log}" 2>&1
echo_progress_done

echo_progress_start "Configuring pyLoad"
echo "/opt/pyload" > /opt/pyload/module/config/configdir

cat > /opt/pyload/pyload.conf << PYCONF
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

echo_progress_start "Initalizing database"
read < <(
    /opt/.venv/pyload/bin/python2 /opt/pyload/pyLoadCore.py > /dev/null 2>&1 &
    echo $!
)
PID=$REPLY
sleep 10
#kill -9 $PID
while kill -0 $PID > /dev/null 2>&1; do
    sleep 1
    kill $PID > /dev/null 2>&1
done

if [ -f "/opt/pyload/files.db" ]; then
    sqlite3 /opt/pyload/files.db "\
    INSERT INTO users('name', 'password') \
      VALUES('${user}','${HASH}');\
      "
    echo_progress_done
else
    echo_error "Something went wrong with user setup -- you will be unable to login"
    #TODO maybe exit then?
fi

chown -R ${user}: /opt/pyload
mkdir -p /home/${user}/Downloads
chown ${user}: /home/${user}/Downloads

echo_progress_start "Insatlling systemd service"
cat > /etc/systemd/system/pyload.service << PYSD
[Unit]
Description=pyLoad
After=network.target

[Service]
User=${user}
ExecStart=/opt/.venv/pyload/bin/python2 /opt/pyload/pyLoadCore.py --config=/opt/pyload
WorkingDirectory=/opt/pyload

[Install]
WantedBy=multi-user.target
PYSD
echo_progress_done

if [[ -f /install/.nginx.lock ]]; then
    echo_progress_start "Configuring nginx"
    bash /usr/local/bin/swizzin/nginx/pyload.sh
    systemctl reload nginx
    echo_progress_done
fi
echo_progress_start "Enabling and starting pyLoad services"
systemctl enable -q --now pyload.service 2>&1 | tee -a $log
echo_progress_done

echo_success "PyLoad installed"
touch /install/.pyload.lock

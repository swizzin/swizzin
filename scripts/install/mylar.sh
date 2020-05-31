#!/bin/bash
# Mylar Installer for Swizzin
# Author: Public920

if [[ -f /tmp/.install.lock ]]; then
    log="/root/logs/install.log"
else
    log="/root/logs/swizzin.log"
fi

user=$(cut -d: -f1 < /root/.master.info)
password=$(cut -d: -f2 < /root/.master.info)
codename=$(lsb_release -cs)

if [[ $codename =~ ("xenial"|"bionic"|"stretch") ]]; then
    . /etc/swizzin/sources/functions/pyenv
    pyenv_install
    pyenv_install_version 3.8.1
    pyenv_create_venv 3.8.1 /opt/.venv/mylar
else
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y update >> $log 2>&1
    apt-get -q -y install python3-dev python3-pip python3-venv >> $log 2>&1
    mkdir -p /opt/.venv/mylar
    python3 -m venv /opt/.venv/mylar
fi

mkdir /opt/mylar
curl -s https://api.github.com/repos/mylar3/mylar3/releases/latest \
    | grep tarball_url \
    | cut -d '"' -f 4 \
    | tr -d \" \
    | xargs -n 1 curl -sSL \
    | tar -xz -C /opt/mylar --strip-components=1  >> $log 2>&1
/opt/.venv/mylar/bin/pip3 install -r /opt/mylar/requirements.txt >> $log 2>&1

chown -R ${user}: /opt/mylar
chown -R ${user}: /opt/.venv/mylar

cat > /opt/mylar/config.ini <<MYCONF
[General]
oldconfig_version = None
auto_update = False
cache_dir = /opt/mylar/cache
dynamic_update = 4
refresh_cache = 7
annuals_on = False
syno_fix = False
launch_browser = False
wanted_tab_off = False
enable_rss = False
search_delay = 1
grabbag_dir = None
highcount = 0
maintainseriesfolder = False
destination_dir = None
multiple_dest_dirs = None
create_folders = True
delete_remove_dir = False
upcoming_snatched = True
update_ended = False
folder_scan_log_verbose = False
interface = default
correct_metadata = False
move_files = False
rename_files = False
folder_format = $Series ($Year)
file_format = $Series $Annual $Issue ($Year)
replace_spaces = False
replace_char = None
zero_level = False
zero_level_n = None
lowercase_filenames = False
ignore_havetotal = False
ignore_total = False
ignore_covers = True
snatched_havetotal = False
failed_download_handling = False
failed_auto = False
preferred_quality = 0
use_minsize = False
minsize = None
use_maxsize = False
maxsize = None
autowant_upcoming = True
autowant_all = False
comic_cover_local = False
add_to_csv = True
skipped2wanted = False
read2filename = False
send2read = False
nzb_startup_search = False
unicode_issuenumber = False
alternate_latest_series_covers = False
show_icons = False
format_booktype = False
cleanup_cache = False
secure_dir = None
encrypt_passwords = False
config_version = 10

[Update]
locmove = False
newcom_dir = None
fftonewcom_dir = False

[Scheduler]
rss_checkinterval = 20
search_interval = 360
download_scan_interval = 5
check_github_interval = 360
blocklist_timer = 3600

[Weekly]
alt_pull = 2
pull_refresh = None
weekfolder = False
weekfolder_loc = None
weekfolder_format = 0
indie_pub = 75
biggie_pub = 55
pack_0day_watchlist_only = True
reset_pullist_pagination = True

[Interface]
http_port = 8090
http_host = 127.0.0.1
http_username = ${user}
http_password = ${password}
http_root = /mylar
enable_https = False
https_cert = /opt/mylar/server.crt
https_key = /opt/mylar/server.key
https_chain = None
https_force_on = False
host_return = None
authentication = 0
login_timeout = 43800
alphaindex = True

[API]
api_enabled = False
api_key = None

[CV]
cvapi_rate = 2
comicvine_api = None
blacklisted_publishers = None
cv_verify = True
cv_only = True
cv_onetimer = True
cvinfo = False

[Logs]
log_dir = /opt/mylar/logs
max_logsize = 10000000
max_logfiles = 5
log_level = 1

[Git]
git_path = None
git_user = mylar3
git_branch = None
check_github = False
check_github_on_startup = False

[Perms]
enforce_perms = True
chmod_dir = 0777
chmod_file = 0660
chowner = None
chgroup = None

[Import]
add_comics = False
comic_dir = None
imp_move = False
imp_paths = False
imp_rename = False
imp_metadata = False
imp_seriesfolders = True

[Duplicates]
dupeconstraint = None
ddump = False
duplicate_dump = None
duplicate_dated_folders = False

[Prowl]
prowl_enabled = False
prowl_priority = 0
prowl_keys = None
prowl_onsnatch = False

[PUSHOVER]
pushover_enabled = False
pushover_priority = 0
pushover_apikey = None
pushover_device = None
pushover_userkey = None
pushover_onsnatch = False
pushover_image = False

[BOXCAR]
boxcar_enabled = False
boxcar_onsnatch = False
boxcar_token = None

[PUSHBULLET]
pushbullet_enabled = False
pushbullet_apikey = None
pushbullet_deviceid = None
pushbullet_channel_tag = None
pushbullet_onsnatch = False

[TELEGRAM]
telegram_enabled = False
telegram_token = None
telegram_userid = None
telegram_onsnatch = False
telegram_image = False

[SLACK]
slack_enabled = False
slack_webhook_url = None
slack_onsnatch = False

[DISCORD]
discord_enabled = False
discord_webhook_url = None
discord_onsnatch = False

[Email]
email_enabled = False
email_from = ""
email_to = ""
email_server = ""
email_user = ""
email_password = ""
email_port = 25
email_enc = 0
email_ongrab = True
email_onpost = True

[PostProcess]
post_processing = False
file_opts = move
snatchedtorrent_notify = False
local_torrent_pp = False
post_processing_script = None
pp_shell_location = None
enable_extra_scripts = False
es_shell_location = None
extra_scripts = None
enable_snatch_script = False
snatch_shell_location = None
snatch_script = None
enable_pre_scripts = False
pre_shell_location = None
pre_scripts = None
enable_check_folder = False
check_folder = None

[Providers]
provider_order = ""
usenet_retention = 1500

[Client]
nzb_downloader = 0
torrent_downloader = 0

[SABnzbd]
sab_host = None
sab_username = None
sab_password = None
sab_apikey = None
sab_category = None
sab_priority = Default
sab_to_mylar = False
sab_directory = None
sab_version = None
sab_client_post_processing = False

[NZBGet]
nzbget_host = None
nzbget_port = None
nzbget_username = None
nzbget_password = None
nzbget_priority = None
nzbget_category = None
nzbget_directory = None
nzbget_client_post_processing = False

[Blackhole]
blackhole_dir = None

[NZBsu]
nzbsu = False
nzbsu_uid = None
nzbsu_apikey = None
nzbsu_verify = True

[DOGnzb]
dognzb = False
dognzb_apikey = None
dognzb_verify = True

[Newznab]
newznab = False
extra_newznabs = ""

[Torznab]
enable_torznab = False
extra_torznabs = ""

[Experimental]
experimental = False
altexperimental = False

[Tablet]
tab_enable = False
tab_host = None
tab_user = None
tab_pass = None
tab_directory = None

[StoryArc]
storyarcdir = False
copy2arcdir = False
arc_folderformat = None
arc_fileops = copy
upcoming_storyarcs = False
search_storyarcs = False

[Metatagging]
enable_meta = False
cmtagger_path = None
cbr2cbz_only = False
ct_tag_cr = True
ct_tag_cbl = True
ct_cbz_overwrite = False
unrar_cmd = None
ct_notes_format = Issue ID
ct_settingspath = None
cmtag_volume = True
cmtag_start_year_as_volume = False
setdefaultvolume = False

[Torrents]
enable_torrents = False
enable_torrent_search = False
minseeds = 0
enable_public = False
public_verify = True

[DDL]
allow_packs = False
enable_ddl = False
ddl_location = None
ddl_autoresume = True

[AutoSnatch]
auto_snatch = False
auto_snatch_script = None
pp_sshhost = None
pp_sshport = 22
pp_sshuser = None
pp_sshpasswd = None
pp_sshlocalcd = None
pp_sshkeyfile = None

[Watchdir]
torrent_local = False
local_watchdir = None

[Seedbox]
torrent_seedbox = False
seedbox_host = None
seedbox_port = None
seedbox_user = None
seedbox_pass = None
seedbox_watchdir = None

[32P]
enable_32p = False
search_32p = False
deep_search_32p = False
mode_32p = False
rssfeed_32p = None
passkey_32p = None
username_32p = None
password_32p = None
verify_32p = True

[Rtorrent]
rtorrent_host = None
rtorrent_authentication = basic
rtorrent_rpc_url = None
rtorrent_ssl = False
rtorrent_verify = False
rtorrent_ca_bundle = None
rtorrent_username = None
rtorrent_password = None
rtorrent_startonload = False
rtorrent_label = None
rtorrent_directory = None

[uTorrent]
utorrent_host = None
utorrent_username = None
utorrent_password = None
utorrent_label = None

[Transmission]
transmission_host = None
transmission_username = None
transmission_password = None
transmission_directory = None

[Deluge]
deluge_host = None
deluge_username = None
deluge_password = None
deluge_label = None
deluge_pause = False
deluge_download_directory = ""
deluge_done_directory = ""

[qBittorrent]
qbittorrent_host = None
qbittorrent_username = None
qbittorrent_password = None
qbittorrent_label = None
qbittorrent_folder = None
qbittorrent_loadaction = default

[OPDS]
opds_enable = False
opds_authentication = False
opds_username = None
opds_password = None
opds_metainfo = False
opds_pagesize = 30
MYCONF

cat > /etc/systemd/system/mylar.service <<MYLRSD
[Unit]
Description=Mylar
After=syslog.target network.target

[Service]
Type=forking
User=${user}
Group=${user}
ExecStart=/opt/.venv/mylar/bin/python3 /opt/mylar/Mylar.py -d --pidfile /run/${user}/mylar.pid --datadir /opt/mylar --nolaunch --config /opt/mylar/config.ini --port 8090
PIDFile=/run/${user}/mylar.pid
Restart=on-failure

[Install]
WantedBy=multi-user.target
MYLRSD

systemctl daemon-reload >> $log 2>&1
systemctl enable --now mylar >> $log 2>&1

if [[ -f /install/.nginx.lock ]]; then
    bash /usr/local/bin/swizzin/nginx/mylar.sh
    systemctl reload nginx
    echo "Install complete! Please note Mylar access url is: https://$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')/mylar/home"
fi

touch /install/.mylar.lock

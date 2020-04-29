#!/bin/bash
# Nginx configuration for Headphones
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cut -d: -f1 < /root/.master.info)

active=$(systemctl is-active headphones)
if [[ $active == "active" ]]; then
  systemctl stop headphones
fi

if [[ ! -f /etc/nginx/apps/headphones.conf ]]; then
  cat > /etc/nginx/apps/headphones.conf <<RAD
location /headphones {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:8004/headphones;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
RAD
fi
cat > /opt/headphones/config.ini <<HPCONF
[General]
nzb_downloader = 0
download_torrent_dir = ""
keep_torrent_files_dir = ""
file_permissions_enabled = 1
encoderquality = 2
search_interval = 1440
libraryscan = 1
folder_permissions = 0755
ignore_clean_releases = 0
http_password = ""
numberofseeders = 10
open_magnet_links = 0
git_user = rembo10
add_album_art = 0
preferred_quality = 0
headphones_indexer = 0
album_art_max_width = ""
rename_files = 0
file_format = $Track $Artist - $Album [$Year] - $Title
customhost = 127.0.0.1
customport = 5000
interface = default
folder_format = $Artist/$Album [$Year]
album_art_min_width = ""
move_files = 0
cleanup_files = 0
replace_existing_folders = 0
preferred_bitrate_allow_lossless = 0
embed_album_art = 0
music_encoder = 0
check_github_on_startup = 1
encodervbrcbr = cbr
http_port = 8004
xldprofile = ""
delete_lossless_files = 1
cue_split = 1
autowant_all = 0
official_releases_only = 0
magnet_links = 0
log_dir = /opt/headphones/logs
torrentblackhole_dir = ""
update_db_interval = 24
ignored_words = ""
hppass = ""
freeze_db = 0
encoder_multicore_count = 0
git_branch = master
https_cert = /opt/headphones/server.crt
http_root = /headphones
download_dir = ""
http_proxy = 0
git_path = ""
launch_browser = 1
required_words = ""
advancedencoder = ""
http_username = ""
lossless_destination_dir = ""
https_key = /opt/headphones/server.key
cache_dir = /opt/headphones/cache
cue_split_flac_path = ""
mb_ignore_age = 365
libraryscan_interval = 300
file_underscores = 0
soft_chroot = ""
rename_unprocessed = 1
keep_nfo = 0
preferred_bitrate_high_buffer = 0
blackhole = 0
customsleep = 1
keep_torrent_files = 0
lossless_bitrate_from = 0
api_key = ""
do_not_override_git_branch = 0
include_extras = 0
usenet_retention = 1500
samplingfrequency = 44100
rename_frozen = 1
http_host = 127.0.0.1
enable_https = 0
encoder_path = ""
hpuser = ""
encoderlossless = 1
torrent_downloader = 0
detect_bitrate = 0
torrent_removal_interval = 720
blackhole_dir = ""
keep_original_folder = 0
extras = ""
autowant_manually_added = 1
encoder_multicore = 0
encoderfolder = ""
mirror = musicbrainz.org
album_art_format = folder
preferred_bitrate = ""
preferred_words = ""
folder_permissions_enabled = 1
check_github = 1
custompass = ""
destination_dir = ""
api_enabled = 0
correct_metadata = 0
encoder = ffmpeg
customuser = ""
download_scan_interval = 5
cue_split_shntool_path = ""
bitrate = 192
wait_until_release_date = 0
music_dir = ""
auto_add_artists = 1
do_not_process_unmatched = 0
lastfm_username = ""
embed_lyrics = 0
autowant_upcoming = 1
config_version = 5
check_github_interval = 360
preferred_bitrate_low_buffer = 0
customauth = 0
file_permissions = 0644
prefer_torrents = 0
encoderoutputformat = mp3
lossless_bitrate_to = 0
[Growl]
growl_enabled = 0
growl_onsnatch = 0
growl_host = ""
growl_password = ""
[Advanced]
ignored_files = ,
verify_ssl_cert = 1
album_completion_pct = 80
ignored_folders = ,
cache_sizemb = 32
journal_mode = wal
[XBMC]
xbmc_update = 0
xbmc_notify = 0
xbmc_username = ""
xbmc_enabled = 0
xbmc_password = ""
xbmc_host = ""
[Email]
email_smtp_user = ""
email_onsnatch = 0
email_tls = 0
email_smtp_port = 25
email_smtp_server = ""
email_ssl = 0
email_smtp_password = ""
email_to = ""
email_enabled = 0
email_from = ""
[Waffles]
waffles_passkey = ""
waffles = 0
waffles_ratio = ""
waffles_uid = ""
[NZBget]
nzbget_category = ""
nzbget_priority = 0
nzbget_password = ""
nzbget_username = nzbget
nzbget_host = ""
[Synoindex]
synoindex_enabled = 0
[Apollo.rip]
apollo_url = https://apollo.rip
apollo_ratio = ""
apollo = 0
apollo_username = ""
apollo_password = ""
[Plex]
plex_token = ""
plex_client_host = ""
plex_notify = 0
plex_server_host = ""
plex_enabled = 0
plex_username = ""
plex_update = 0
plex_password = ""
[Old Piratebay]
oldpiratebay = 0
oldpiratebay_ratio = ""
oldpiratebay_url = ""
[Twitter]
twitter_username = ""
twitter_prefix = Headphones
twitter_onsnatch = 0
twitter_enabled = 0
twitter_password = ""
[Pushover]
pushover_apitoken = ""
pushover_onsnatch = 0
pushover_enabled = 0
pushover_keys = ""
pushover_priority = 0
[Slack]
slack_onsnatch = 0
slack_emoji = ""
slack_channel = ""
slack_url = ""
slack_enabled = 0
[NZBsorg]
nzbsorg_hash = ""
nzbsorg_uid = ""
nzbsorg = 0
[NMA]
nma_priority = 0
nma_onsnatch = 0
nma_apikey = ""
nma_enabled = 0
[Piratebay]
piratebay_proxy_url = ""
piratebay_ratio = ""
piratebay = 0
[Deluge]
deluge_host = ""
deluge_paused = 0
deluge_done_directory = ""
deluge_cert = ""
deluge_label = ""
deluge_password = ""
[Newznab]
newznab = 0
newznab_enabled = 1
extra_newznabs = ,
newznab_host = ""
newznab_apikey = ""
[Prowl]
prowl_onsnatch = 0
prowl_enabled = 0
prowl_keys = ""
prowl_priority = 0
[SABnzbd]
sab_host = ""
sab_category = ""
sab_password = ""
sab_username = ""
sab_apikey = ""
[Redacted]
redacted_username = ""
redacted_password = ""
redacted_ratio = ""
redacted = 0
[Transmission]
transmission_username = ""
transmission_host = ""
transmission_password = ""
[Telegram]
telegram_enabled = 0
telegram_token = ""
telegram_onsnatch = 0
telegram_userid = ""
[Torznab]
extra_torznabs = ,
torznab_host = ""
torznab_enabled = 1
torznab_apikey = ""
torznab = 0
[Subsonic]
subsonic_host = ""
subsonic_password = ""
subsonic_enabled = 0
subsonic_username = ""
[Songkick]
songkick_apikey = nd1We7dFW2RqxPw8
songkick_location = ""
songkick_filter_enabled = 0
songkick_enabled = 1
[uTorrent]
utorrent_password = ""
utorrent_label = ""
utorrent_host = ""
utorrent_username = ""
[Kat]
kat = 0
kat_ratio = ""
kat_proxy_url = ""
[QBitTorrent]
qbittorrent_username = ""
qbittorrent_host = ""
qbittorrent_password = ""
qbittorrent_label = ""
[omgwtfnzbs]
omgwtfnzbs = 0
omgwtfnzbs_uid = ""
omgwtfnzbs_apikey = ""
[LMS]
lms_enabled = 0
lms_host = ""
[Pushalot]
pushalot_apikey = ""
pushalot_enabled = 0
pushalot_onsnatch = 0
[Rutracker]
rutracker = 0
rutracker_password = ""
rutracker_ratio = ""
rutracker_user = ""
[tquattrecentonze]
tquattrecentonze_password = ""
tquattrecentonze_user = ""
tquattrecentonze = 0
[PushBullet]
pushbullet_deviceid = ""
pushbullet_apikey = ""
pushbullet_enabled = 0
pushbullet_onsnatch = 0
[OSX_Notify]
osx_notify_onsnatch = 0
osx_notify_app = /Applications/Headphones
osx_notify_enabled = 0
[Mininova]
mininova_ratio = ""
mininova = 0
[Strike]
strike = 0
strike_ratio = ""
[Boxcar]
boxcar_enabled = 0
boxcar_token = ""
boxcar_onsnatch = 0
[Beets]
idtag = 0
[MPC]
mpc_enabled = 0
HPCONF

if [[ $active == "active" ]]; then
  systemctl start headphones
fi

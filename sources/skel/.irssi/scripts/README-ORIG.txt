
This is an auto downloader for Irssi.

Features:
[*] ruTorrent plugin (optional).
[*] Supports your favorite tracker
[*] Advanced but easy to use filters. No complicated regex required, not even wildcards for TV shows and movies.
[*] Some of the filters: release, size, tracker, resolution, source (eg. BluRay), category, format (eg. FLAC), bitrate, and many more.
[*] Torrent can be saved to a watch directory, or uploaded to uTorrent webui or an FTP server.
[*] Option to set max downloads per day/week/month
[*] Torrent data folder name can use info from the torrent or current date (eg. "dated" folders)
[*] No broken .torrent files are ever uploaded to your client. Torrent files are verified before uploading them.
[*] Duplicate releases are not downloaded by default.
[*] Torrents are downloaded in the background so Irssi isn't blocked.
[*] SSL downloads can be forced.
[*] Automatic updates.
[*] Automatically connects to IRC servers and channels
[*] Wake on LAN

It can be downloaded here: http://sourceforge.net/projects/autodl-irssi/

[URL=http://img38.imageshack.us/i/filters1.png/][IMG]http://img38.imageshack.us/img38/3294/filters1.png[/IMG][/URL]
[URL=http://img197.imageshack.us/i/filters2e.png/][IMG]http://img197.imageshack.us/img197/1296/filters2e.png[/IMG][/URL]
[URL=http://img163.imageshack.us/i/filters3.png/][IMG]http://img163.imageshack.us/img163/9039/filters3.png[/IMG][/URL]
[URL=http://img535.imageshack.us/i/prefs1.png/][IMG]http://img535.imageshack.us/img535/6194/prefs1.png[/IMG][/URL]
[URL=http://img39.imageshack.us/i/servers1.png/][IMG]http://img39.imageshack.us/img39/153/servers1.png[/IMG][/URL]




[b]Installation[/b]

The install script will install autodl-irssi and optionally also ruTorrent, the ruTorrent plugin and any other dependencies required to have a fully working ruTorrent install. It will ask a few questions and then install whatever you selected.

[b]Ubuntu and Ubuntu clones[/b]:
[code]
cd
wget --no-check-certificate -O autodl-setup http://sourceforge.net/projects/autodl-irssi/files/autodl-setup/download
sudo sh autodl-setup
[/code]

[b]Any other OS[/b]
Log in as root:
[code]su -[/code]
Then install it:
[code]
wget --no-check-certificate -O autodl-setup http://sourceforge.net/projects/autodl-irssi/files/autodl-setup/download
sh autodl-setup
[/code]


To use the autodl-irssi ruTorrent plugin, click its icon at the top of ruTorrent. It's usually the icon to the left of ruTorrent's settings icon. The icon is either a white bubble or a white down arrow inside a green square. The autodl-irssi tab will show all autodl-irssi output as long as ruTorrent is loaded.



If you don't use the ruTorrent plugin, then you may want to send all autodl-irssi output to its own window:
By default, all autodl-irssi output goes to the [b](status)[/b] window. If there's a window called [b]autodl[/b], then it will write all output to that window. Use these Irssi commands to create a new window named [b]autodl[/b] and place it right after the status window (i.e., window position 2):
[code]First start Irssi! :D
/window new hidden
/window name autodl
/window move 2
/layout save
/save[/code]


Since some people don't want users to have shell access, it's also possible to disable the "exec" action. Create [b]/etc/autodl.cfg[/b] and add this:

[code]
[options]
allowed = watchdir, rtorrent
[/code]

That will only enable the rtorrent and "Save to watch dir" actions. The following can be used with the [b]allowed[/b] option:

rtorrent
watchdir
webui (requires uTorrent)
ftp
exec
dyndir (requires uTorrent)

It's a comma seperated list, eg.: allowed = watchdir, ftp



[b]Manual installation[/b]

If you can't use the installer for some reason, then try a manual install.

autodl-irssi requires Irssi compiled with Perl support.

autodl-irssi has the following Perl module dependencies:
* Archive::Zip
* Net::SSLeay
* HTML::Entities
* XML::LibXML
* Digest::SHA1
* JSON
* JSON::XS (optional)

Use your package manager to install them or use the CPAN utility. If you use CPAN, you will need a build environment already installed, eg. gcc, make, etc.

[code]
cpan Archive::Zip Net::SSLeay HTML::Entities XML::LibXML Digest::SHA1 JSON JSON::XS
[/code]

The optional ruTorrent plugin has the following PHP dependencies:
* json
* sockets
* xml

You can test for the presence of those modules by executing the following command. If you get no output then they're installed:

[code]for module in json xml sockets; do php -m|grep -wq $module || echo "Missing module: $module"; done[/code]

Use your package manager to install them unless they're already installed. You may need to edit your php.ini file by adding this:

[code]
extension=sockets.so
extension=json.so
extension=xml.so
[/code]

Don't forget to restart your web server if you make any changes to php.ini.


Installing autodl-irssi. Note: Make sure you're [b]not[/b] root when you execute the following commands.
[code]
mkdir -p ~/.irssi/scripts/autorun
cd ~/.irssi/scripts
wget -O autodl-irssi.zip http://sourceforge.net/projects/autodl-irssi/files/autodl-irssi-v1.31.zip/download
unzip -o autodl-irssi.zip
rm autodl-irssi.zip
cp autodl-irssi.pl autorun/
mkdir -p ~/.autodl
touch ~/.autodl/autodl.cfg
[/code]

The autodl-irssi startup script has been copied to the autorun directory so it will be started automatically when Irssi is started.


Installing the optional ruTorrent plugin. You may need to slightly modify the steps if you're not using Ubuntu or if ruTorrent isn't installed to /var/www/rutorrent/

[code]
cd /var/www/rutorrent/plugins
sudo svn co https://autodl-irssi.svn.sourceforge.net/svnroot/autodl-irssi/trunk/rutorrent/autodl-irssi
sudo cp autodl-irssi/_conf.php autodl-irssi/conf.php
sudo chown -R www-data:www-data autodl-irssi
[/code]

This install assumes ruTorrent is not password protected. For password protected (i.e., multi-user) setup, you need to copy conf.php to the user plugins directory and not to the plugin directory. Eg. you need to copy it to a path similar to /var/www/rutorrent/conf/users/YOUR-USER-NAME/plugins/autodl-irssi

Edit conf.php with a text editor and add your port number and password. The port number should be a random number between 1024 and 65535 inclusive. The file should look something like this afterwards:

[code]
<?php
$autodlPort = 12345;
$autodlPassword = "secretpass";
?>
[/code]

Open ~/.autodl/autodl2.cfg with a text editor and add this to the file:
[code]
[options]
gui-server-port = 12345
gui-server-password = secretpass
[/code]

If you start more than one Irssi process, make sure each Irssi process uses a unique port number! It won't work if they all use the same port number.


[b]The autodl.cfg file[/b]

NOTE: If you're using the ruTorrent plugin, you don't need to read this! :D

All filters and other options are read from ~/.autodl/autodl.cfg. If you use non-ASCII characters, be sure to set the encoding (or character coding) to UTF-8 before saving it. The file will be automatically re-read whenever you make any modifications to it when autodl-irssi is running.

If you have used the ChatZilla auto downloader, I wrote a program that will convert autodl-cz's options into a format understood by autodl-irssi. See [b]Using autodl-cz's options[/b] somewhere near the bottom.

Here's an example autodl.cfg file you can modify:
[quote]
# Lines beginning with a '#' character are ignored (i.e., they're comments!)

# TV-shows/movies template: (note that wildcards aren't necessary in the [b]shows[/b] filter option!)
[filter TV SHOW MOVIE FILTER TEMPLATE]
shows = The Simpsons, Other show, 3rd Show, Some movie, Movie #2
max-size = 2GB
#seasons = 3-8
#episodes = 0-99
resolutions = SD, 720p
sources = HDTV, DVDRip, BluRay
encoders = xvid, x264
#years = 2008-2012, 1950
#match-sites =

# Music template:
[filter MUSIC FILTER TEMPLATE]
match-sites = what, waffles
min-size = 30MB
max-size = 1GB
years = 1950-1969, 2000, 2009-2099
#shows = ArtistOrGroup #1, ArtistOrGroup #2, etc
#albums = Album #1, Album #2, etc
formats = MP3, FLAC
bitrates = v0 (vbr), lossless
media = CD
#tags = hip hop, tag #2, tag #3
#tags-any = true
#except-tags = hip hop, tag #2, tag #3
#except-tags-any = false
#scene =
#log =
#cue =

# Random scene releases:
[filter RANDOM SCENE RELEASE FILTER TEMPLATE]
match-releases = the?simpsons*, american?dad*, blah*
except-releases = *-LOL, *-crapgroup, crap.release*
#match-sites =
#except-sites =
#min-size = 10MB
max-size = 500MB
#max-pretime = 3 secs
#match-uploaders =
#except-uploaders =

# All releases from a certain category:
[filter CATEGORY FILTER TEMPLATE]
match-categories = *MP3*, *XVID*
#except-categories = *XXX*
#match-releases =
#except-releases =
#match-sites =
#except-sites =
#min-size =
max-size = 10GB

[filter rtorrent stuff]
match-releases = Some.Random.Release-GRP
# ... etc
upload-type = rtorrent
rt-dir = /home/YOURNAME/downloads/$(Month)$(Day)/$(Tracker)
#rt-commands = print="Added: $(TorrentName)"; print="Hello, world!"
rt-label = $(Tracker)
#rt-ratio-group = rat_3
#rt-channel = thr_2
rt-priority = high
#rt-ignore-scheduler = true
#rt-dont-add-name = false

[options]
max-saved-releases = 1000
save-download-history = true
download-duplicates = false
upload-type = watchdir
#upload-type = webui
#upload-type = ftp
upload-watch-dir = /home/username/watchdir
upload-ftp-path = /

[webui]
user = 
password = 
hostname = 
port = 
ssl = 

[ftp]
user = 
password = 
hostname = 
port = 

[tracker scc]
authkey =
[/quote]

All lines starting with the # character are ignored (they're comments). Use it to disable some options.

The file contains several headers of the form [b][headername][/b] and header options immediately below the header. The options are of the form [b]option-name = option-value[/b]. If you leave out the value or option-name, then the default value will be used.

There are a few different option types:
Comma separated list. eg. [b]value1, value2, value3[/b].
List of numbers. eg. [b]1980-1999, 2010, 2012[/b]
String. Any number of random characters.
Integer. Any integer.
Boolean. [b]false[/b], [b]off[/b], [b]no[/b], or [b]0[/b] all mean "false". Anything else means "true".
Size. eg. [b]120 MB[/b] or [b]4.5GB[/b]

All option values are case-insensitive so eg. [b]The Simpsons[/b] is the same thing as [b]the siMPSonS[/b].

The comma separated list type supports wildcards, where the [b]*[/b] character means 0 or more characters, and the [b]?[/b] character means exactly one character. Google wildcards for more information. Example, [b]*simpsons*[/b] will match any text with the word simpsons in it. It means [b]First 0 or more characters, then "simpsons", then 0 or more characters[/b]. Note that [b]simpsons*[/b] is not the same thing, it means [b]First "simpsons" then 0 or more characters[/b], so [b]simpsons*[/b] will match anything that begins with the word "simpsons" followed by any text.

[b]The filter header[/b]
Create one [filter] header per filter. You can optionally name the filter like [b][filter MY FILTER NAME][/b]. All filter options are optional! If you don't use any filter options, then everything will be downloaded because your filter doesn't filter out anything.

[b]Name:[/b] enabled
[b]Type:[/b] Boolean
[b]Default:[/b] true
[b]Example:[/b] enabled = false
[b]Description:[/b] Use it to disable a filter. All filters are enabled by default.

[b]Name:[/b] match-releases
[b]Type:[/b] Comma separated list
[b]Example:[/b] match-releases = The?Simpsons*, American?Dad*
[b]Description:[/b] It's compared against the torrent name, eg. [b]Some.release.720p.HDTV-GROUP[/b]. If the filter should only match TV-shows or movies, it's easier to use the [b]shows[/b] filter option since it doesn't require wildcards.

[b]Name:[/b] except-releases
[b]Description:[/b] The exact opposite of [b]match-releases[/b]. If a release matches this option, then it's NOT downloaded.

[b]Name:[/b] match-categories
[b]Type:[/b] Comma separated list
[b]Example:[/b] match-categories = *MP3*, TV/XVID
[b]Description:[/b] It's compared against the torrent category.

[b]Name:[/b] except-categories
[b]Description:[/b] The exact opposite of [b]except-categories[/b]. If a release matches this option, then it's NOT downloaded.

[b]Name:[/b] match-sites
[b]Type:[/b] Comma separated list
[b]Example:[/b] match-sites = tracker1, tracker2, tracker3
[b]Description:[/b] It's compared against the tracker. Use the full tracker name, eg. MyTracker or use one of the tracker types found in ~/.irssi/scripts/AutodlIrssi/trackers/*.tracker. Open one of the files and locate the [b]type="XYZ"[/b] line. Use the value inside the quotes, eg. [b]XYZ[/b].

[b]Name:[/b] except-sites
[b]Description:[/b] The exact opposite of [b]match-sites[/b]. If a release matches this option, then it's NOT downloaded.

[b]Name:[/b] min-size
[b]Type:[/b] Size
[b]Example:[/b] min-size = 200MB
[b]Default:[/b] 0
[b]Description:[/b] Used to filter out too small torrents.

[b]Name:[/b] max-size
[b]Type:[/b] Size
[b]Example:[/b] max-size = 2.5GB
[b]Default:[/b] any size is allowed
[b]Description:[/b] Used to filter out too big torrents. I recommend everyone to always use this option so you don't accidentally download a 100GB torrent! :D Set it to a reasonable value, eg. for TV-shows, set it to about twice the size of a normal episode (just in case it's a double-episode). This will automatically filter out season packs!

[b]Name:[/b] shows
[b]Type:[/b] Comma separated list
[b]Example:[/b] shows = The Simpsons, American Dad
[b]Description:[/b] This is for TV-shows, movies and artists/groups (what.cd/waffles only). autodl-irssi will automatically extract the TV-show/movie name from a scene release name. Example, The.Simpsons.S35E24.720p.HDTV-BLAH will match a [b]shows[/b] option set to [b]the simpsons[/b]. You don't need wildcards at all, though it's possible to use wildcards. It's recommended to use [b]shows[/b] instead of [b]match-releases[/b] if all you want is for the filter to match TV-shows or movies. what.cd and waffles: this will match against the artist/group.

[b]Name:[/b] seasons
[b]Type:[/b] List of numbers
[b]Example:[/b] seasons = 1, 3, 5-10
[b]Description:[/b] This is for TV-shows only. Unless the release matches one of the seasons, it's not downloaded.

[b]Name:[/b] episodes
[b]Type:[/b] List of numbers
[b]Example:[/b] episodes = 1, 3, 5-10
[b]Description:[/b] This is for TV-shows only. Unless the release matches one of the episodes, it's not downloaded.

[b]Name:[/b] resolutions
[b]Type:[/b] Comma separated list
[b]Example:[/b] resolutions = SD, 720p, 1080p
[b]Description:[/b] This is for TV-shows and movies only. Unless the release matches one of the resolutions, it's not downloaded. Valid resolutions are one or more of the following: [b]SD[/b], [b]480i[/b], [b]480p[/b], [b]576p[/b], [b]720p[/b], [b]810p[/b], [b]1080i[/b], [b]1080p[/b].

[b]Name:[/b] sources
[b]Type:[/b] Comma separated list
[b]Example:[/b] sources = HDTV, DVDRip, BluRay
[b]Description:[/b] This is for TV-shows and movies only. Unless the release matches one of the sources, it's not downloaded. Valid sources are one or more of the following: [b]DSR[/b], [b]PDTV[/b], [b]HDTV[/b], [b]HR.PDTV[/b], [b]HR.HDTV[/b], [b]DVDRip[/b], [b]DVDScr[/b], [b]BDr[/b], [b]BD5[/b], [b]BD9[/b], [b]BDRip[/b], [b]BRRip[/b], [b]DVDR[/b], [b]MDVDR[/b], [b]HDDVD[/b], [b]HDDVDRip[/b], [b]BluRay[/b], [b]WEB-DL[/b], [b]TVRip[/b], [b]CAM[/b], [b]R5[/b], [b]TELESYNC[/b], [b]TS[/b], [b]TELECINE[/b], [b]TC[/b]. [b]TELESYNC[/b] and [b]TS[/b] are synonyms (you don't need both). Same for [b]TELECINE[/b] and [b]TC[/b].

[b]Name:[/b] encoders
[b]Type:[/b] Comma separated list
[b]Example:[/b] encoders = x264, xvid
[b]Description:[/b] If you don't want windows WMV files, this option could be useful. :) Valid encoders are: [b]XviD[/b], [b]DivX[/b], [b]x264[/b], [b]h.264[/b] (or [b]h264[/b]), [b]mpeg2[/b] (or [b]mpeg-2[/b]), [b]VC-1[/b] (or [b]VC1[/b]), [b]WMV[/b].

[b]Name:[/b] years
[b]Type:[/b] List of numbers
[b]Example:[/b] years = 1999, 2005-2010
[b]Description:[/b] Not all releases have a year in the torrent name, but if it does, you can use it to filter out too old or too new releases.

[b]Name:[/b] albums
[b]Type:[/b] Comma separated list
[b]Example:[/b] albums = Some album, Some other album, yet another one
[b]Description:[/b] what.cd/waffles only.

[b]Name:[/b] formats
[b]Type:[/b] Comma separated list
[b]Example:[/b] formats = MP3, FLAC
[b]Description:[/b] what.cd/waffles only. List the formats you want. Valid formats are: [b]MP3[/b], [b]FLAC[/b], [b]Ogg[/b], [b]AAC[/b], [b]AC3[/b], [b]DTS[/b].

[b]Name:[/b] bitrates
[b]Type:[/b] Comma separated list
[b]Example:[/b] bitrates = 192, V0 (vbr), lossless
[b]Description:[/b] what.cd/waffles only. List the bitrates you want. Some example values: [b]192[/b], [b]320[/b], [b]APS (VBR)[/b], [b]V2 (VBR)[/b], [b]V1 (VBR)[/b], [b]APX (VBR)[/b], [b]V0 (VBR)[/b], [b]q8.x (VBR)[/b], [b]Lossless[/b], [b]24bit Lossless[/b], [b]Other[/b].

[b]Name:[/b] media
[b]Type:[/b] Comma separated list
[b]Example:[/b] media = CD, WEB
[b]Description:[/b] what.cd/waffles only. List the media you want. Valid media are: [b]CD[/b], [b]DVD[/b], [b]Vinyl[/b], [b]Soundboard[/b], [b]SACD[/b], [b]DAT[/b], [b]Cassette[/b], [b]WEB[/b], [b]Other[/b].

[b]Name:[/b] tags
[b]Type:[/b] Comma separated list
[b]Example:[/b] tags = hip hop, rock
[b]Description:[/b] what.cd/waffles only. Unless at least one of your tags matches the release's tags, it's not downloaded. See also [b]except-tags[/b] and [b]tags-any[/b].

[b]Name:[/b] except-tags
[b]Type:[/b] Comma separated list
[b]Example:[/b] except-tags = hip hop, rock
[b]Description:[/b] what.cd/waffles only. Same as [b]tags[/b] except if it matches any/all of these, it's not downloaded. See also [b]tags[/b] and [b]except-tags-any[/b].

[b]Name:[/b] tags-any
[b]Type:[/b] Boolean
[b]Default:[/b] true
[b]Example:[/b] tags-any = false
[b]Description:[/b] what.cd/waffles only. Decides how to match the [b]tags[/b] option, ie., if any or all of the tags must match.

[b]Name:[/b] except-tags-any
[b]Type:[/b] Boolean
[b]Default:[/b] true
[b]Example:[/b] except-tags-any = true
[b]Description:[/b] what.cd/waffles only. Decides how to match the [b]except-tags[/b] option, ie., if any or all of the tags must match.

[b]Name:[/b] scene
[b]Type:[/b] Boolean
[b]Example:[/b] scene = true
[b]Description:[/b] what.cd/waffles, and a few others. Some sites mark a release as scene or non-scene. Set it to true if you want only scene releases, false if you only want non-scene releases, or don't use this option if you don't care.

[b]Name:[/b] log
[b]Type:[/b] Boolean
[b]Example:[/b] log = true
[b]Description:[/b] what.cd/waffles. Set it to true if you only want releases with a log file, false if you don't want releases with log files, or don't use this option if you don't care.

[b]Name:[/b] cue
[b]Type:[/b] Boolean
[b]Example:[/b] cue = true
[b]Description:[/b] what.cd. Set it to true if you only want releases with a cue file, false if you don't want releases with cue files, or don't use this option if you don't care.

[b]Name:[/b] match-uploaders
[b]Type:[/b] Comma separated list
[b]Example:[/b] match-uploaders = uploader1, uploader2
[b]Description:[/b] Use it to only download from certain uploaders.

[b]Name:[/b] except-uploaders
[b]Description:[/b] The exact opposite of [b]match-uploaders[/b]. If a release matches this option, then it's NOT downloaded.

[b]Name:[/b] max-pretime
[b]Type:[/b] time-since string
[b]Example:[/b] max-pretime = 2 mins 3 secs
[b]Description:[/b] Some sites announce the pretime of the release. Use this to filter out old releases.

[b]Name:[/b] max-downloads
[b]Type:[/b] Integer
[b]Example:[/b] max-downloads = 15
[b]Description:[/b] Download no more than this number of torrents per week/month (see [b]max-downloads-per[/b]). Remove the filter option or set it to a negative number to disable it.

[b]Name:[/b] max-downloads-per
[b]Type:[/b] String
[b]Example:[/b] max-downloads-per = week
[b]Description:[/b] Valid values are [b]day[/b], [b]week[/b], and [b]month[/b]. See [b]max-downloads[/b].

[b]The options header[/b]
These options change the behavior of autodl-irssi. Place these options below the [b][options][/b] header.

[b]Name:[/b] rt-address
[b]Type:[/b] string
[b]Default:[/b] Whatever is found in ~/.rtorrent.rc
[b]Example:[/b] rt-address = 127.0.0.1:5000
[b]Description:[/b] If you use the 'rtorrent' action ([b]upload-method[/b]), then you must initialize this to your rtorrent's SCGI address. It can be ip:port (eg. 127.0.0.1:5000) or /path/to/socket. [b]NOTE:[/b] This option can only be set in autodl2.cfg, [b]not[/b] autodl.cfg.


[b]Name:[/b] update-check
[b]Type:[/b] string
[b]Default:[/b] ask
[b]Example:[/b] update-check = auto
[b]Description:[/b] autodl-irssi can auto update itself. Valid values are [b]ask[/b], [b]auto[/b], and [b]disabled[/b]. [b]ask[/b] will print a message when there's a new version. [b]auto[/b] will automatically update it when there's a new version. [b]disabled[/b] won't do a thing when there's a new update.

[b]Name:[/b] max-saved-releases
[b]Type:[/b] Integer greater than or equal to 0.
[b]Default:[/b] 1000
[b]Example:[/b] max-saved-releases = 200
[b]Description:[/b] autodl-irssi will remember the last [b]max-saved-releases[/b] releases you have downloaded so it won't re-download the same file again. Only useful if [b]save-download-history[/b] is enabled.

[b]Name:[/b] save-download-history
[b]Type:[/b] Boolean
[b]Default:[/b] true
[b]Example:[/b] save-download-history = true
[b]Description:[/b] Set it to false to disable writing the last N (= [b]max-saved-releases[/b]) downloaded releases to ~/.autodl/DownloadHistory.txt.

[b]Name:[/b] download-duplicates
[b]Type:[/b] Boolean
[b]Default:[/b] false
[b]Example:[/b] download-duplicates = true
[b]Description:[/b] By default, it's false so no duplicate releases are downloaded. Set it to true if you want to download the same release again if it's re-announced.

[b]Name:[/b] unique-torrent-names
[b]Type:[/b] Boolean
[b]Default:[/b] false
[b]Example:[/b] unique-torrent-names = true
[b]Description:[/b] If true, all saved torrent filenames are unique (the site name is prepended to the filename). Set it to false to use the torrent release name as the filename.

[b]Name:[/b] download-retry-time-seconds
[b]Type:[/b] Integer
[b]Default:[/b] 300
[b]Example:[/b] download-retry-time-seconds = 120
[b]Description:[/b] If a download fails, autodl-irssi will try to re-download it after waiting a little while. If it still can't download it after [b]download-retry-time-seconds[/b] seconds, it will give up and report an error.

[b]Name:[/b] path-utorrent
[b]Type:[/b] String
[b]Default:[/b] nothing
[b]Example:[/b] path-utorrent = /cygdrive/c/Program Files (x86)/uTorrent/uTorrent.exe
[b]Description:[/b] Set it to the path of uTorrent if you're using an [b]upload-type[/b] equal to [b]dyndir[/b].


[b]Sending Wake on LAN (WOL)[/b]
It's possible to wake up the computer before uploading the torrent (uTorrent webui or FTP upload). You may need to make sure your BIOS and network card have WOL enabled.

wol-mac-address = 00:11:22:33:44:55
wol-ip-address = 12.34.56.78  (or a DNS name, eg. www.blah.com)
wol-port = 9 (defaults to 9 if you leave it blank)

[b]wol-mac-address[/b] is the MAC (or hardware) address of the computer's network card. Use ifconfig /all (windows) or ifconfig -a (Linux) to find out your network card's MAC address.

If you have a router, then set [b]wol-ip-address[/b] to your router's public IP address, and make sure the router forwards UDP packets to port [b]wol-port[/b] (default 9) to your router's internal broadcast address (usually 192.168.0.255).


[b]Torrent action options[/b]
autodl-irssi can save a torrent file to a watch directory, upload it to uTorrent webui, upload it to an FTP server, execute a program or use uTorrent to save it to a dynamic directory name that depends on the current torrent.

There's a global action option in the [options] header and a local action option in each filter. By default, the global action option is used but you can override it in any filter by placing a new [b]upload-type[/b] below your [filter] header.

[b]rtorrent only:[/b]
[quote]
upload-type = rtorrent
rt-dir = /home/YOURNAME/downloads/$(Month)$(Day)/$(Tracker)
rt-commands = print="Added: $(TorrentName)"; print="Hello, world!"
rt-label = $(Tracker)
#rt-ratio-group = rat_3
#rt-channel = thr_2
rt-priority = high
#rt-ignore-scheduler = true
#rt-dont-add-name = false
[/quote]

[b]rt-dir[/b] is the destination directory. The torrent data will be saved here. Macros can be used.
[b]rt-commands[/b] can be used to execute some rtorrent commands when loading the torrent file. It's for advanced users only.
[b]rt-label[/b] is used to set a ruTorrent label.
[b]rt-ratio-group[/b] is used to set a ruTorrent ratio group. Valid names are rat_0, rat_1, ..., rat_7. You must have the ratio ruTorrent plugin installed.
[b]rt-channel[/b] is used to set a ruTorrent channel. Valid names are thr_0, thr_1, ..., thr_9. You must have the throttle ruTorrent plugin installed.
[b]rt-priority[/b] sets the torrent priority. Valid values are 0, dont-download, 1, low, 2, normal, 3, high. If you set it to dont-download (or 0), the torrent is loaded, but not started.
[b]rt-ignore-scheduler[/b]: set it to true to disable the ruTorrent scheduler.
[b]rt-dont-add-name[/b]: set it to true if you don't want the torrent name to be added to the path.


[b]Save torrent to a watch directory:[/b]
[quote]
upload-type = watchdir
upload-watch-dir = /home/myusername/mywatchdir
[/quote]

[b]Upload torrent to uTorrent webui:[/b]
Don't forget to initialize webui user, password, etc below the [webui] header!
[quote]
upload-type = webui
[/quote]

[b]Upload torrent to an FTP server:[/b]
Don't forget to initialize FTP user, password, etc below the [ftp] header!
[quote]
upload-type = ftp
upload-ftp-path = /ftp/server/path
[/quote]

[b]Execute a program:[/b]
[quote]
upload-type = exec
upload-command = /path/to/program
upload-args = all arguments here
[/quote]

Both [b]upload-command[/b] and [b]upload-args[/b] support macros. See Macros below for an explanation of all available macros. Just remember to enclose the macro in double quotes if it's possible that the macro contains spaces. Example: [b]upload-args = --torrent "$(TorrentPathName)" --category $(Category)[/b]


[b]Save torrent data to a dynamic directory using uTorrent:[/b]
You need to initialize [b]path-utorrent[/b] below [options] or it won't work!
[quote]
upload-type = dyndir
upload-dyndir = c:\the\windows\path\$(macro)$(macro2)\$(macro3)
[/quote]

Important: autodl-irssi assumes that the Z: drive is mapped to your / (root) directory if you're using Wine to run uTorrent.

[b]upload-dyndir[/b] supports macros. See Macros below for an explanation of all available macros. You can use macros to create a directory based on current day and month. Some examples:

[b]upload-dyndir = c:\mydownloads\$(year)-$(month)-$(day)[/b] will save the torrent data below a directory containing the current year, month and day. Eg. [b]c:\mydownloads\2010-10-28[/b] if 2010-10-28 happened to be the current day.

[b]upload-dyndir = c:\mydownloads\$(month)$(day)\$(trackershort)\$(category)[/b] will save the data to a directory based on current month, day, tracker name, and torrent category.

[b]The webui header[/b]
[quote]
[webui]
user =
password =
hostname =
port =
ssl =
[/quote]
user is user name, password is your password, hostname is the IP-address (uTorrent only wants IP-addresses), and port is the webui port. Set [b]ssl = true[/b] to enable encrypted uploads or false to use normal non-encrypted uploads. Read here on how to enable HTTPS webui: http://www.utorrent.com/documentation/webui

[b]The FTP header[/b]
[quote]
[ftp]
user =
password =
hostname =
port =
[/quote]
user is user name, password is your password, hostname is the hostname/IP-address, and port is the FTP port.


[b]The IRC options header[/b]
auto-connect = true
Set it to true to enable auto connecting to IRC servers and channels.

user-name =
real-name =
IRC user name and real name. Leave blank if we should use Irssi's settings.

output-server =
output-channel =
Send all autodl-irssi output to the specified IRC server and channel. Make sure you've setup autodl-irssi to auto connect to the IRC server and channel.


[b]The tracker header[/b]
Your trackers require that you authenticate before letting you download a torrent file. Use the tracker headers to set the required options so downloads work.

A tracker header looks like [b][tracker TYPE][/b] where [b]TYPE[/b] is the tracker type. This is the exact same type that you find in the [b]~/.irssi/scripts/AutodlIrssi/trackers/*.tracker[/b] files. Open one of the files with a text editor and locate the [b]type="XYZ"[/b] line. Use the value inside the quotes, eg. [b]XYZ[/b]. Example: [b][tracker XYZ][/b]. Case matters so XYZ is different from xyz.

Some trackers require a [b]passkey[/b], others an [b]authkey[/b], or a [b]cookie[/b], etc. To quickly find out which one your tracker needs, just add [b][tracker TYPE][/b] (with no options below it) to autodl.cfg and wait 1-2 seconds (start Irssi if necessary). It will report the missing options, eg.: [b]ERROR: /home/YOURNAME/.autodl/autodl.cfg: line 123: TRACKER-TYPE: Missing option(s): passkey, uid[/b]. Here it's saying that you forgot to add the options [b]passkey = XXX[/b] and [b]uid = YYY[/b]. Add them below the tracker header.

Some common tracker options and how to get them:

[b]cookie[/b]: Go to your tracker's home page, then type [b]javascript:document.innerHTML=document.cookie[/b] in the address bar and press enter. You should now see your cookie. If all you see is PHPSESSID=XXXXX, then you'll have to manually get the cookie using FireFox: Edit -> Preferences -> Privacy tab -> Show Cookies. It's usually just [b]uid=XXX; pass=YYY[/b]. Separate each key=value pair with a semicolon.

[b]passkey[/b]: First check a torrent download link if it contains it. If not you can usually find it in the generated RSS-feed URL, which you probably can generate @ yourtracker.com/getrss.php . passkeys are usually exactly 32 characters long. The passkey can also sometimes be found in your profile (click your name).

[b]authkey[/b]: See [b]passkey[/b] above. For gazelle sites, it's part of the torrent download link.

[b]torrent_pass[/b]: For gazelle sites, it's part of the torrent download link.

[b]uid[/b]: Click your username and you should see the id=XXX in the address bar. That's your user id, or uid.

[tracker TYPE]
#enabled =
#force-ssl =
#upload-delay-secs =
#cookie =
#passkey =
#etc ...

[b]enabled[/b] is optional and defaults to true. Set it to false to disable the tracker.
[b]force-ssl[/b] is optional and can be set to true to force encrypted torrent downloads. Not all trackers support HTTPS downloads. Leave it blank for the default value (which is HTTP or HTTPS).
[b]upload-delay-secs[/b] is optional and is the number of seconds autodl-irssi should wait before uploading/saving the torrent. Default is 0 (no wait). This option isn't needed 99.999% of the time.



[b]Macros[/b]

Current date and time: [b]$(year)[/b], [b]$(month)[/b], [b]$(day)[/b], [b]$(hour)[/b], [b]$(minute)[/b], [b]$(second)[/b], [b]$(milli)[/b]
[b]$(TYear)[/b] is the year of the torrent release, not current year.
[b]$(Artist)[/b], [b]$(Show)[/b], [b]$(Movie)[/b], [b]$(Name1)[/b] all mean the same thing.
[b]$(Album)[/b], [b]$(Name2)[/b] both mean the same thing.
[b]$(Site)[/b] is tracker URL.
[b]$(Tracker)[/b] is long tracker name.
[b]$(TrackerShort)[/b] is short tracker name.
[b]$(TorrentPathName)[/b] is the path to the .torrent file (unix path if you're using cygwin).
[b]$(WinTorrentPathName)[/b] is the windows path to the .torrent file.
[b]$(InfoHash)[/b] This is the "info hash" of the torrent file.

The rest are possibly self explanatory: [b]$(Category)[/b], [b]$(TorrentName)[/b], [b]$(Uploader)[/b], [b]$(TorrentSize)[/b], [b]$(PreTime)[/b], [b]$(TorrentUrl)[/b], [b]$(TorrentSslUrl)[/b], [b]$(Season)[/b], [b]$(Episode)[/b], [b]$(Resolution)[/b], [b]$(Source)[/b], [b]$(Encoder)[/b], [b]$(Format)[/b], [b]$(Bitrate)[/b], [b]$(Media)[/b], [b]$(Tags)[/b], [b]$(Scene)[/b], [b]$(Log)[/b], [b]$(Cue)[/b]

[b]$(Season2)[/b] and [b]$(Episode2)[/b] are two-digit season and episode numbers.





[b]Using autodl-cz's options[/b]
This part explains how to re-use autodl-cz's options.

You need the XML::LibXSLT Perl module to run this script. Some other Perl modules are also required but they're installed by the installer.

It's important that you are using at least version 2.03 of autodl-cz! After upgrading it, run it once and go to Auto Downloader -> Preferences. Press OK and it will save all options in the 2.03 (or later) format. Failure to do this may result in a pretty useless autodl.cfg file.

Start ChatZilla and type [b]/pref profilePath[/b] and press enter. Copy your profilePath, which is something like [b]/home/YOURNAME/.mozilla/firefox/XXXXXXXXX.default/chatzilla[/b], and append [b]/autodl/settings/autodl.xml[/b] so you get something like [b]/home/YOURNAME/.mozilla/firefox/XXXXXXXXX.default/chatzilla/scripts/autodl/settings/autodl.xml[/b]. That's the path to your autodl-cz's options file. Now type this in your terminal (add your path below):

[code]
mkdir -p ~/.autodl
wget http://sourceforge.net/projects/autodl-irssi/files/convertxml.pl/download
perl convertxml.pl /home/YOURNAME/.mozilla/firefox/XXXXXXXXX.default/chatzilla/scripts/autodl/settings/autodl.xml > ~/.autodl/autodl.cfg[/code]

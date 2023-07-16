# Changelog

## [3.9.1]

## July 16, 2023

### Development:
- add pre-commit.ci integration

### Fixed:
- mango: stop offering to install mango on arm because it's unsupported
- updates: add echos to all update actions
- rtorrent: build shared libs for curl (should fix compile errors related to zlib)
- rtorrent: autoremove after repo clean (should fix segfaults related to xmlrpc-c)

## [3.9.0]

## June 26, 2023

### New:

- os: bookworm support
- os: use gcc-12 in Jammy

### Changed:

- deluge: compile flags are more optmized
- qbittorrent: use O3 compile flag

### Fixed:

- nzbhydra: broken variable
- mylar: urllib3 pip depends
- curl: use cmake
- curl: don't use curl to install curl
- rtorrent: udns can't use ipv6

## [3.8.0]

## May 4, 2023

### New:

- rtorrent: add UDNS install option
- rtorrent: compile a fancier, featureful version of curl

### Changed:

- rutorrent: enable localhostedmode (will load much faster now!)
- autodl: change some downloading logic
- rutorrent: install ffmpeg by default
- rutorrent: update config for v4.1.4

### Fixed:

- let's encrypt: respects ecc certs for hooks
- sabnzbd: python packaging logic for v4 (python3 < 3.8)
- bazarr: python packing logic improvements and remove EOL support (python3 < 3.8)
- rtorrent: limit piece preloading to torrents uploading at 50KB/s+ (no updater script for this. [It's a simple config change if you want this](https://github.com/swizzin/swizzin/commit/cd3519824a8b7dc631d2d709533024533c87aac8))
- nginx: remove duplicate packages from install params
- rutorrent: arm64 support for filemanager (reinstall the plugin if this is you)

## [3.7.1]

## April 15, 2023

### Updated
- rutorrent: version 4.0.2, 4.0.3 compatibility

### Fixed
- rtorrent:
  - resolve lockfile crash
  - patch xmlrpc-c for newer architectures
  - support 10gbit throttles
  - lower repo priority on the installation options
- nextcloud: version pinned everything except jammy
- lounge: remove problematic `npm config set`

## [3.7.0]

## April 2, 2023

This release is mainly aimed at improving the ruTorrent issues as a result of a recent surge in development, but a few other improvements made it in as well.

### New
- New application: jfa-go

### Changed
- qbittorrent: disabled 4.5 branch on buster due to gcc incompatibilities
- rtorrent: compiliation improvements and better LTO settings thanks to @stickz
- rtorrent: installation speed improvements thanks to @stickz
- php: will now set path in the pool config, avoiding the need to manually set path in ruTorrent configs
- readme: removed more feathub links

### Fixed
- rtx: revert to filemanager pinning on 4.0 rutorrent version
- rtx: better tag detection of your current installation
- rtx: ensure rutorrent directory is a git safe.dir
- rutorrent: better version matching, avoid beta releases now that 4.0 is stable
- rutorrent: botched scgi creation
- quota: fix rutorrent diskspace creation (use existing function rather than duplicate code)
- wireguard: finally found the pesky bug causing rt kernel to be installed in buster (should be generally more functional in buster now as well)
- box list: not showing package names

## [3.6.0]

## January 21, 2023

### Changed
 - Do not use git.io links for quick setup. Bespoke s5n.sh links have been setup for this
 - Stretch and Bionic have officially been EOL'd. The current commit will be retagged for eol-bionic and eol-stretch. Please update your OS to something that isn't 5+ years old
 - rtx now supports some rudimentary cli options for installing plugins and themes without the GUI
 - qBittorrent now supports version 4.5
 - Deluge 2.1 is supported
 - Node version has been bumped to version 18 LTS

### Fixed
 - qBittorrent now has some better error handling
 - Deluge Automat version has been pinned


## [3.5.3]

## October 15, 2022

### Changed
 - qbittorrent: installs now default to RC_1_2 libtorrent branch for 4.4.x (following upstream). You may choose to compile with RC_2_0 if you `export LIBTORRENT_VERSION=RC_2_0` before install.
 - panel: added proper log management/levels


### Fixed
 - fpm: fixed installation on stretch, bionic and buster
 - netdata: uninstall now exists (again)
 - mango: fixed dl links
 - calibre: libopengl0 
 - nginx/php: add zip module
 - rutorrent: fix version sorting, install latest
 - rtx: fix version grepping for tag support in many plugins
 - rutorrent: un-pin filemanager plugin
 - deluge: don't chmod deluge.UpdateTracker.py
 - qbit: removed useless code
 - panel: fixed log spam of missing profiles (nginx, vsftp, quota, rclone, ffmpeg, etc) 

## [3.5.2]

## September 2, 2022

### New
 - rtorrent: add user patch support

### Fixed

 - transmission: add support for nginx fancy index download endpoint
 - jellyfin: support new install settings/locations
 - wireguard: postdown script was adding the nat rule instead of deleting it

## [3.5.1]

## July 10, 2022

### Fixed
 - x2go: debian keychain quirk
 - prevent log clobbering from certain commands
 - rtx: DarkBetter and MaterialDesign themes are ruTorrent submodules now
 - jellyfin: fix apt dependency resolution

## [3.5.0]

### New
 - Ubuntu Jammy Support (22.04)
 - Add b to funding. Toss him some money.

### Updated
 - The Lounge will now use yarn for the install method. Existing installs will be swapped to the new method.
 - ruTorrent installs will no longer install club-quickbox theme by default. The theme needs work to be compatible with v4

### Fixed
 - Pull git repo updates as user owning repo (Ubuntu CVE fix)
 - Update the *arr nginx configs
 - apt-key is deprecated, use current best practices for pulling in keys
    - Existing keys won't be updated. You will only start to see noisy warnings starting in Jammy, so this will only potentially affect you if you dist-upgrade, but keys previously via apt-key will still work
 - hold rtorrent/qbittorrent packages when compiled
 - wireguard wasn't installing iptables even though it depends on it
 - emby upgrader qol fixes and suspiciously missing arm support
 - qbittorrent 4.4.3.1 update broke version matching because it was fuzzy, now it is not.

### Upstream issues
 - Jellyfin builds are known not to work under Jammy. This is not our fault. Track here for info on when this is resolved.
    - https://github.com/jellyfin/jellyfin/issues/7742

## [3.4.0]

### New
 - Readarr has finally left beta

### Fixed
 - rtorrent: optimize performance (thanks stickz!)
 - qbittorrent: fix git tagging for qttools compiles
 - bazarr: fix proxy setup bad sed

## [3.3.2]

## Feb 18, 2022

Hotfix release

### Fixed
 - radarr: properly setting host variable in the reverse proxy (todo: lidarr, etc)
 - flood: fixed an issue which was causing an unresolvable issue during `box update`
 - sabnzbd: bump pyenv version requirements
 - rutorrent(filemanager): pinned filemanager-share/media packages to match fm

## [3.3.1]

## Feb 13, 2022

Hotfix release

### Fixed
 - grep in check_installed function will now make a more reliable check. It was sometimes greedily matching the string "not-installed" causing apt_install to skip the package.
 - Pinned filemanager-rutorrent to last known working commit as the latest commit is broken and causing ruTorrent to not load.
 - Mango pushed another config change which caused the app to break.

## [3.3.0]

## Feb 12, 2022

Some good fixes in this release that have been some glaring issues for a little while now. Major improvements to the ruTorrent install-flow, enabling qbit 4.4 builds and fixing broken flood compiles.

Also, lots of first time contributors in this release. Thank you for your contributions!

### Updated
 - qBittorrent
   - qBittorrent now has support for version 4.4.*
     - These builds utilize libtorrent 2.0 and QT6
     - Thanks to @userdocs and their contributions to providing us a github workflow to produce the deb builds used in the new version for cmake/qt6 automagically
   - qBittorrent reverse proxy will now properly write the cookie path
 - ruTorrent
   - ruTorrent will now pin to the latest version tag on install. Master has become a bit unstable so this should provide a better experience for everybody. swizzin has generated some logic to keep installs rolling with the most recent tag.
   - `rtx` is now version aware when you install plugins will do its best to install a plugin from a matching version tag
   - pulled the autodl-plugin into our organization and applied the patches to make it work with ruTorrent 4
   - If you are still having version issues and plugin problems, please uninstall and reinstall ruTorrent -- we don't officially support upgrades, so a reinstallation would be the best way to resolve outstanding issues at this point. Be aware some settings/traffic data may be lost. I would encourage you to backup your ruTorrent folder (/srv/rutorrent) first if you value this data and would like to attempt to restore it.
 - rTorrent
   - Community members have provided patches to help fix some instabilities to rTorrent:
     - bencode dos vulnerabilities in rTorrent 0.9.6 (@static53)
     - fix a crash in rTorrent when xmlrpc receives invalid data (@stickz)
   - rTorrent has internally received some TLC and code updates as the rtorrent code is some of the first that was ever contributed to this repo
 - Flood
   - We now use jesec's fork and npm install this package globally. Existing users of flood will need to reinstall their package to receive updates moving forward. We no longer compile flood on a per-user basis. Regretfully some double authentication issues remain; however, I determined this to be the best solution since we have support for all the backends flood supports. If you take issue with the new layout, see the reasoning [here](https://github.com/swizzin/swizzin/pull/579#issuecomment-1030685911)
 - mango
   - updated the default config and push new config on mango upgrades (@rubysamurai)
 - mylar
   - cleaned up some issues preventing a clean experience on a fresh installation
 - `box`
   - The box management script has received some TLC in the form of refactoring 
   - `apt_install` function will now do some checks and only inform you about the packages it is actually installing

### Internal/Development notes
 - New function `github_latest_version` in the utils functions
   - `github_latest_version mylar3/mylar3` queries the release page of the org/project and returns the latest version of a package. You can then use this version to generate your case statement to download stuff based on architecture.
 - Restructured patches to live in `sources/patches/appname`


## [3.2.0]

## January 1, 2022

Happy new year! Due to some recent, major bugs, swizzin is getting an update today to fix some issues with AutoDL and Deluge 1.3. Also a few new apps and some other fixes.

Enjoy!

### Added
 - Navidrome
 - Mylar
 - Debug functions

### Updated
  - Node to 16 LTS

### Fixed
 - Some bazarr variables were returning as null and creating chatter
 - Incorrect python version being used during `box chpasswd` with Deluge 1.3 installed
 - Branch used when installing 1.3-stable of Deluge
 - Calibre-web installer to update venv requirements on upgrade and remove the deprecated `-f` flag
 - Pinned ruTorrent to a known working commit to prevent a fatal error with outdated autodl
 - Nextcloud broke download links for older versions

## [3.1.1]

## October 14, 2021

### Added
 - `populate_var` function for swizdb toolkit

### Updated
 - Node version bump to 14 LTS.
   - We will no longer clobber your choices if you are running a newer node version than is required by swizzin packages

### Fixed
 - apt function `check_install` was sometimes improperly returning the installed status of dependencies

## [3.1.0]

## September 20, 2021

### Added
 - New app: Autobrr
   - A torrent client agnostic replacement for Autodl-irssi written in go.
   - Still in active development. The author was kind enough to contribute the entire flow to swizzin, which is why it has been included despite being in active development.
   - Consider not using it quite yet if you are afraid of potentially having to reinstall the application and reset-up your filters in the event an app upgrade requires a full database wipe. That said, the application currently does what it says on the box.
 - Checking out the `develop` branch will keep you on `develop` over future runs of `box update`

### Updated
 - Sonarr installations will now use the tarball method of install rather than the apt repo (fixes Bullseye "no repo found" for Sonarr)
 - Include arm64 in official support during install
 - nginx will now default to TLS1.3 and http/2 connections
 - made tests a bit less noisy
 - Offer to remove mysql database when removing nextcloud

### Fixed
 - Autodl grepping for gui/server ports could accidentally return the wrong port if your client was fully setup.
 - `/home/${user}/.config` will now be generated when creating/adding a user to prevent scenarios in which `~/.config` is created and owned by `root`
 - Parsing `--test` and `--env` arguments during setup
 - enable pre-allocation in qbittorrent by default (XFS users rejoice)
 - Calibre: `os_arch` command not found during upgrade
 - Filebrowser arm compatibility was broken on upgrades

## [3.0.0] was technically months ago edition

## August 16, 2021

### Added
 - develop branch
 - Styled echos (@flying-sausages)
   - We are working to make the installers more quiet and streamlined. If you notice anything odd or out of place, feel free to bring it up!
 - ARMv64 support
 - Radarr v3 (dotnet)
   - #diemono
 - Prowlarr (@bakerboy448)
 - Ombi v4 -- ombi v3 is no more
 - Airsonic (@flying-sausages)
 - Calibre, Content server and Calibre-web (@flying-sausages)
 - `sources/globals.sh` loads the most commonly used functions. Useful for writing your own scripts or debugging swizzin or reasons
 - Actually upgrade plex if you run `box upgrade plex` after the install installation of the update script
 - `box upgrade lounge`
 - `touch /etc/swizzin/.dev.lock` to prevent `box update` from forcing you to git head. Useful for troubleshooting or saying "stop updating my swizz"
 - Reboot required detection at the end of `setup.sh`
 - Unattended setup. Please see related docs for info on how to use (accepts arguments and env files)
 - cracklib is now mandatory when choosing an account password, unless you can read the docs
   - Please make sure you elevate to root properly `su -` is the correct command, not `su`. A note has been added to the readme.
 - Echo ports at the end of installers if nginx is not installed
 - bash completion (@userdocs)
 - `swizdb`: functions for a persistent storage of swizzin application-related config options
 - `box test` (mostly for dev QoL) 

### Removed
 - Xenial support (stretch life support notice ~ June 2022)
   - Last commit supporting xenial lives at tag: xenial-eol. Please consider upgrading your server!
 - Sonarr v2 (old stable)
 - Couchpotato
 - Headphones
 - Subsonic
 - Revert: Add Komga -- it's probably not coming back

### Updated
 - Libtorrent static libraries: any version of qBittorrent can be installed with any version of Deluge.
   - Deluge and qBittorrent now use static libraries built directly into the apps themselves. This allows them to be version agnostic which will be important for retaining compatibility with upcoming qBittorrent versions while maintaining compatibility with the slower pace of Deluge development.
   - Libtorrent will accept a patch at `/root/libtorrent-${libtorrent_branch}.patch` if you would like to change the settings of libtorrent before compilation
      - During upgrades Deluge and qBittorrent will ask to continue to use the existing version of libtorrent if it deems the current version acceptable for the requested change
   - Bullseye will likely be the last OS supporting Deluge 1.3.15 as steps will not be taken to maintain python2 compatibility if/when distros purge python2 packages
 - Jellyfin: Use apt-get to install the jellyfin packages from the officially maintained repositories
 - Quick start: Made the quick-start command shorter and more memorable. Added the `source` to help prevent `box` post-install confusion.
 - Librespeed: update nginx config
 - Refined global depends (added things like `jq`)
 - Some usernames cannot be used when adding a user
 - pip2 is install from getpip if using bullseye or focal
 - Websocket support for Mango
 - rar/unrar install function
 - update sabnzbd:
   - Support 3.2.0
   - Update python version requirements
   - Pre-write config template to prevent infinite `sleep`
 - Update backports management
 - Pin nextcloud to v20 on Bionic
 - Code quality cleanups
 - Allow subdirectories in `/etc/nginx/apps`
 - Removed ungraceful ExecStop command for `deluged`
 - \*arr scripts are becoming more uniform
 - Ensure swizzin directory perms stay correct between updates
 - Moved to opt:
   - Lounge
   - sabnzbd
 - Add config purging to ombi
 - Use upstream removal script for netdata
 - Add equivalent of apt-get install --only-upgrade to `apt_install`
 - Moved unzip to global depends

### Fixed
 - qBittorrent depends were getting a bit too heavy. All deps are installed without use of recommends for qBittorrent and qt-related libraries.
   - ***FOCAL ERRATA:*** By default, focal recommended to install an entire x server, mesa, gnome3 and a display manager, gdm, simply for requesting two qt development packages. If you find your server "crashing" or stop responding, it's probably suspending due to power management provided by `gdm`. Gnome 3 is an entire desktop package and the entire x11 server along with gnome3 and gdm can be safely purged if you run a headless server. If you installed gnome or a gui on purpose, you know who you are.
   - It does not appear Debian has ever had this issue.
 - Fixed an issue with nginx + remote torrent adder extension & php
 - Lots of bug fixes all throughout qbit and deluge scripts during rewrite
 - Refine panel (`swizzin`) user permissions and abilities
 - Circumstances in which transmission did not install nginx proxy (all of them)
 - Cat and mouse with python2/pip2 and focal
 - `box upgrade curl` broke a couple times but we fixed it (it's been a long time since we posted a changelog...)
 - jellyfin:
   - cache and metadata paths
   - nginx proxy ip
 - fixed an issue with pyload and setuptools>45 (aka python3 only setuptools)
 - qBittorrent: made the systemd service more graceful
 - Emby and JF cannot be installed side by side, so you will be prevented of this scenario.
 - organizr v21 fixes
 - various pyenv fixes
 - fixed ~/.config permissions to ensure the user always owns this
 - fpm compilation in focal
 - typo in jackett updater script that was causing it to fire unconditionally
 - stretch-related pip maintenance
 - typos in various echos
 - Hotfix jellyfin baseurl and bind ip settings during setup
 - Basic auth was protecting emby for some reason
 - Ensure sonarr is using the correct branch when running its nginx config
 - Fix sonarr timeout when waiting for heartbeat
 - boost mirror died, updated main and added a backup
 - rtorrent mirror died
   - recreated approximate patch-set of the tarball shipped from rtorrent.net for 0.9.6 and patched rtorrent for bullseye
 - ruTorrent: Ensure /srv is created, get rid of cds, remove cloudscraper and python dep
 - Don't spam syslogs with trasmission chatter
 - python2 virtualenv installation of focal/bullseye
 - ensure users can read their own wireguard configs
 - set Let's Encrypt as the default certificate authority (acme.sh now defaults to zerossl)
 - fixed bazarr config for sonarrv3
 - Fixed a few erroneous paths in lounge scripts
 - Fixed a scenario which would cause `box upgrade sabnzbd` to fail
 - bad service name in resilio sync updater
 - kill `box chpasswd` if user does not exist
 - bazarr deployment method has been moved to github releases due to compiled translations

### GitHub Meta
 - Updated issue template that we hope is easier to fill out
 - No longer auto closing issues

### Developer Meta
 - PR Template
 - Use conventional commits to explain changes
 - Utilize CI to make PRs easier
 - Contributing guidelines updated
 - Code is linted for formatting
   - We format with spaces. I can't help if spaces make you feel some kinda way.
 - Editorconfig and workspace preferences for development
 - vscode snippets to make life easier for repetitive functions
 - Recommended extensions to ensure your code is formatted properly 

## [2.6.0]

## October 8, 2020

### Added
- Sonarr v3. Rejoice!
- A couple new global depends (`box update` to get these)
- `apt_install` now accepts `--no-recommends` as a parameter

### Fixed
- qBittorrent was going a little *too* happy when installing depends. qBit will not install recommended pacakges anymore when building.
  - For folks running qbit already, three packages were identified as starting unnecessary services. The following packages are safe to stop their services and/or remove them as well if you had them installed through the qBit build pipeline. ***PLEASE DOUBLE CHECK THESE YOURSELF AND IF IN DOUBT DISABLE SERVICES BEFORE REMOVING THEM!!!!***
    - avahi-daemon (Bonjour, aka, LAN Device Discovery)
    - wpasupplicant (Used for configuring wifi access points)
    - modemmanager (Used for configuring modems)
- Fixed qBit password changing with `chpasswd`
- Fixed force reannounce in the libtorrent 1.2 python binding
- Transmission was improperly setting RPC port when adding multiple users
- Fixed transmission watch directory creation
- Wireguard will now output some debug info in the event of a `modprobe` failure
- Ported python helper scripts to python3
- Jackett complete removal
- Specify `python2.7` as `python` and `python2` are not guaranteed to work under Ubuntu Focal Fossa
- Usernames identified as causing conflicts have been blocked during setup. (i.e. `swizzin` and `admin`)

## [2.5.1]

## September 25, 2020

This is a maintenance release for bugs discovered within the past few days

### Fixed
- Added a check for whether or not the new `apt_install` function is correctly sourced during updates. The updater will prompt you to restart if needed.
  - This is because apt functions are now sourced in `box` rather than individual scripts. When running the update for the first time, box is using the outdated version which doesn't source `apt`. `apt` is correctly sourced on the next run.
- Ensure Deluge and qBittorrent have nginx upstreams configured correctly when adding a new user. Deluge was a regression, qBittorrent was an oversight
- Apt keys are now appropriately imported when installing x2go (apt function regression)
- Removed `--skip-update` flag from apt function (it was made redundant)
- Fixed the `skip_libtorrent_rasterbar` function for Deluge 1.3.* users
- Various update script fixes and improvements (less apt spam, less random app restarts)
- ruTorrent installer has been restructured to do less work when adding a new user
- Wireguard fixes and improvements:
  - Buster will now use backports. Stretch still uses unstable with adjusted pin priority.
  - Improved default interface recognition
  - Fixed non-default interface selection showing only one interface
  - Install wireguard with recommended packages to ensure kernel headers are also installed (required for dkms builds)
- rclone will now use `--allow-other` by default
- rclone removal is now a bit more complete (will leave rclone config though)

## [2.5.0]

## September 22, 2020

Lots has happened in the past few months, thus the relatively arbitrary 4 minor version jump.

As a point of business, both myself and flying-sausage are now accepting donations for the project through github sponsors. Please do consider donating to either of us as your contributions help us stay motivated to keep bringing you new features and work on maintaining the project.

[liaralabs](https://github.com/sponsors/liaralabs)
[flying-sausages](https://github.com/sponsors/flying-sausages)

### Meta (Repo) Changes
- [Discussions](https://github.com/liaralabs/swizzin/discussions) have been enabled! Please use this area instead of Issues for general project related chat and help. Otherwise, we can be found in Discord
- Issue links have been reworked to prevent folks from opening tickets without the bug report template
- Issues will be automatically closed if they are stale or do not follow the template.
- README badges. Fancy!
- Codefactor and Codacy support to help keep our repository well-coded.
- flying-sausages has been hard at work to bring you things like the [Contributing Guidelines](https://github.com/liaralabs/swizzin/blob/master/CONTRIBUTING.md). If you are interesting in creating a pull request, please make sure you read these so your work is in line with the rest of the repository

### Added
- Transmission
- Webmin
- qBittorrent
- Organizr
- Mango
- DuckDNS
- Libtorrent will now run some checks to see if you can skip compiling libtorrent when upgrading/installing Deluge or qBittorrent. You can force a skip of the libtorrent compile by using `export SKIP_LT=True` before running a script which calls the libtorrent functions (Deluge/qBittorrent)
- Libtorrent can be patched during compile (e.g. settings pack). Just make sure the file `/root/libtorrent.patch` is present and it will be applied during libtorrent compiles.
- NZBHydra2 and an automated migration assistant. (`box upgrade nzbhydra`)
- Many new functions have been added for utility and apt purposes. This only concerns folks who intend to write contributions to the project. Mostly `apt` and `utils`


### Updated
- SABnzbd now has an upgrade script and will install `sabyenc` with pip
- Python applications have been moved from home directories to `/opt`. The majority of python packages now rely on virtual environments so that their packaging does not affect your system. Virtual environments are typically found at `/opt/.venv`.
- `setdisk` (the quota setting tool) has been rewritten
- `box` won't keep changing permissions on the swizzin repo now, so `box update` will be quieter
- `letsencrypt` will now run some checks for supported tlds when using the CloudFlare option
- `letsnecrypt` will not automatically stop/start nginx when certs are issued in standalone mode (i.e. not the default domain)
- Setup now is a bit more explicit about master user creation, whiptail dialogs are a bit bigger
- vsftpd and ZNC let's encrypt hooks are now smarter and more resilient
- Tautulli now uses Python3
- SickChill now uses Python3
- Wireguard is now multi-user friendly
- XMLRPC has been pinned to a stable version for rTorrent stability
- Filebrowser now has an upgrade mechanism. `box upgrade filebrowser`
- setup will error and quit if for any reason the initial adduser or password creation fails
- rclone install script is now actually useful
- ZNC PPA for Focal

### Removed
- Changes to `/etc/skel` have been removed. Your skel is safe now.
- NZBHydra 1 has been deprecated.

### Fixed
- Link the fancyindex module directly if it doesn't exist in the nginx directory
- Fix bazarr working directory on updates
- Ensure Deluge-web files are removed with Deluge
- Python2 virtualenv functions on Focal
- Don't attempt to downoad mono 5.18 on Focal (new version in focal repos)
- php restart uses the detected version rather than whatever was defined in your nginx conf
- irssi/autodl was not properly being destroyed if a user was deleted
- Remove screen-related directories when removing a user
- deluge-web.lock is now properly created during install
- rTorrent logging during upgrade actions
- SABnzbd 3.0.* is incompatible with feedparser 6.0.0
- Quassel core installs on Buster
- Ensure held packages are changed if we want to make changes to them
- Deluge install would mess up permissions on the `~/torrents` directory if the installer created that directory.
- Deluge install now adds users to the `www-data` group which fixes web access if rTorrent wasn't installed.
- Jellyfin repo location was changed
- Bazarr pip install was causing issues
- Lidarr now installs libchromafp
- vsftpd didn't have a remove script
- Bazarr logging would clobber the log file
- An issue with the order of operations in x2go install

## [2.1.0]

## April 28, 2020

This is a **massive** release! Over 100 files have been touched and updated with new standards and new ways of handling things like python packages. Special thanks to [@flying-sausages](https://github.com/flying-sausages) for all their help in getting this release ready and offering help with code review.

### Added
- Support for Ubuntu 20.04. This includes marginal python2 support and support for Deluge 1.3.15. Please be advised this may be the last LTS release which supports 1.3.15.
- Jellyfin media server ([@userdocs](https://github.com/userdocs))
- Librespeed speedtest page for your server ([@hwcltjn](https://github.com/hwcltjn))
- New functions for python2 virtual environments, PHP version management ([@flying-sausages](https://github.com/flying-sausages)) and a general place for repeated utils.
- pyenv has been added to add support for python versions which aren't natively supported by the OS
- pyLoad will now automatically configure itself, removing the need for user setup
- `box upgrade curl` will compile the latest version of curl on your server to help combat the curl bug present in Debian Buster.
- sabnzbd now has an upgrade script: `box upgrade sabnzbd`

### Updated
- Most python applications will now utilize a virtual environment in the master user's home directory
- Applications which support Python3 have been upgraded to use it.
- `service` commands have been removed in favour of `systemctl` to create a standard of service management
- `nginx-extras` will no longer be installed. `nginx-full` + the fancy index modules is enough and requires less packages (`extras` modules that are unused were causing new bugs in focal)

### Removed
- Support for Debian Jessie has been officially removed
- The CSF package has been removed. You may still remove the package with `box remove csf` but you can no longer install it.
- python-pip is not a global depend and has been removed from the initial setup

### Fixed
- Version 3.7.7 was accidentally hard-coded into the pyenv virtualenv function
- Lounge lockfile was incorrectly named
- `setfacl` was incorrectly called as `setacl`
- Update scripts should not start services if they were left in a disabled/stopped state
- An issue in the panel update script was resetting custom profiles, this has been fixed.
- `box update` now updates the panel again

## [2.0.0]

### March 30,2020

### Added
- swizzin no longer uses the quickbox_dashboard for system and service information. Introducing a new in-house panel for swizzin by swizzin with <3.

### Updated
- bazarr will now use python3

### Removed
- quickbox_dashboard has been permanently removed. 

### Fixed
- GitHub API changed the output of some of their commands. Autodl was having some issues as a result, but the API change has been worked around.
- Some services which were stopped by the user were restarted erroneously during `box update`
- Deluge 1.3 installs will no longer utilize the `-dev` tag
- Ensure rapidleech sets group permissions for www-data
- Ensure rapidleech nginx conf is actually removed
- SickGear had some install issues
- Libtorrent lock was not properly detected in deluge installation


## [1.7.0]

### February 3, 2020

### Added
- xmr-stak has been deprecated and xmrig has been added in its place. The next time you run `box update`, the script will force an upgrade as long as the `/install/.xmr-stak.lock` continues to exist

### Fixed
- acme.sh (the let's encrypt backend) recently added some checks which could make using the let's encrypt script impossible if calling it by sudo. All acme.sh commands are now "forced" to bypass this.
- Some users have connection issues with certain clients, over SSL. This change should help fix that.
- Fixed a permission issue on new Jackett installations that was causing configuration parameters to not be saved and persist across restarts.
- Removed duplicate proxy headers for Jackett nginx config
- Fixed an issue with jackett failing to automatically update properly.
- Tautulli's internal updater was broken, it is now fixed.
- Update nextcloud nginx configuration for CVE-2019-11043
- Radarr permissions on `~/.config/Radarr` were a bit too permissive.
- Ensure user belongs to emby group.
- A few uninstall packages were leaving crumbs.
- Various `quota` package issues (#239)
- Bazarr package was slightly (mostly) broken
- Mono update logic
- Plex claim token wasn't quite claiming properly

### Changed
- ZNC will search for a backports/PPA version before using the main repo.
- Panel `sudo` commands will no longer log output to `/var/log/auth.log`
- Added the AdoptOpenJDK repo to ensure buster supports Java 8 for subsonic.
- Emby scripts will utilize github for all actions now

## [1.6.0]

### September 2, 2019

### Added

- Support for Deluge v2 for all OS except Debian Jessie
- "Repo" install option for rTorrent
- Option to claim plex server during installation

### Changed

- Nodejs will now install version 10 LTS

### Fixed

- Sonarr apt repo signing key
- npm installation

## [1.5.1]

### August 2, 2019

### Changed
- Refactored code to remove useless cats
- Disable automatic updates for Jackett due to broken updater (for now)

### Fixed
- Changed SSL function password name to prevent variable clobbering on first setups
- Disable lightdm to prevent circumstances where servers might suspend after installing x2go

## [1.5.0]

### July 23, 2019

### Added

- Documentation :boom: Please visit https://swizzin.ltd/docs. The wiki has been deprecated. Pull requests on the docs are welcome at https://github.com/liaralabs/docs.swizzin.ltd. Merge requests will automatically rebuild.
- Support for Debian 10 (may still be bugs)
- Support for PHP7.3
- Bug report templates. Please use these for creating descriptive bug reports the first time, every time.
- Spanish language support for panel

#### Package Additions:

- Filebrowser 2 (thanks to userdocs)
- Bazarr
- Lidarr
- rTorrent 0.9.8 enabled

### Changed

- Many long-winded and re-used functions have been branched to separate function files for ease of future updates. Update the code in one place rather than 3. (eg. mono, rtorrent, deluge)
- Debian 10 did not ship with checkinstall, thus a new package mangaement application has been pulled in: `fpm`
- Split libtorrent compile function from deluge to prep further applications requiring libtorrent.
- Migrated jackett to non-mono version.
  - Beware, known issue: https://github.com/Jackett/Jackett/issues/5208
- Update `ip` variable for `iproute2` version 5 compatibility (for use with xanmod custom kernels)
- Update mono snapshot to 5.18. Less memory leaks! :tada:
- Nextcloud version support has been limited to v15 for operating systems which will not upgrade beyond PHP7.0, as nextcloud has dropped support for 7.0 in its latest versions.
- SickRage is now SickChill
- Update sabnzbd to stable branch (khnielsen)
- Update ruTorrent script for new plugin depends
- rTorrent builds other than feature-bind have been re-enabled for all supported operating systems due to instability in `feature-bind`
- Lounge script has been updated for v3 features
- Plexpy is now Tautulli (I still can't spell that)

### Fixed

- Permissions on the `/etc/nginx/ssl` directory were global readable. This has been resolved.
- Longstanding typo in Jessie for adding the dotdeb php repo key
- Stuck jackett install :tada:
- Added checks to `box adduser` and `box deluser` to prevent clobbering and potential data loss issues.
- Removing flood will no longer remove ruTorrent (oops!)
- xmr-stak build script for new PoW algorithms
- systemd nofiles limit was too low
- Emby install location
- GPG key add for x2go on Debian
- sabnzbd dependency issues during install
- Stray exit 0 in update scripts was causing the update process to terminate early.

## [1.4.0]

### November 15, 2018

### Added

- Wireguard VPN package. Rejoice!
- VSFTPD and ZNC will now use your Let's Encrypt certificate. (d2dyno)

### Changed

- Simplified the rclone install script. (d2dyno)
- Plexpy is not Tautulli. (ooohhh)
- deluge-console will now be installed if choosing a "repo" install. (quarreldazzle)
- Ubuntu installer will now enable universe/multiverse repos
- xmlrpc now uses the advanced version to fix message flooding in the rtorrent gui (kennydeckers)
- Mono will use snapshot v5.8 to prevent issues arising from new versions (\#fuckmono)


### Fixed

- Fixed xmr-stak to use the new Monero PoW algorithm
- Radarr archive names changed slightly, fixed to ensure they still unarchive proper
- Fixed Ombi not starting
- Libtorrent sometimes failed to create a .deb file during compile (quarreldazzle)
- Emby URL structures to prevent install errors (kennydeckers)
- Jackett issues due to their new webserver implementation
- quota.lock wasn't created during install sometimes
- Make /opt if not existing
- `box deluser` will forcefully kill processes of users who are being deleted
- Headphones reverse proxy

### Removed

- clean_log function was useless

## [1.3.0]

### April 27, 2018

### Added

- Support for Ubuntu 18.04 (Bionic Beaver). Compatibility has not been thoroughly tested; however popular apps (rtorrent, nginx, deluge, mono-based, sickrage, etc) have been tested and should be working. Please report any issue you may have.
- Upgrades from 16.04 to 18.04 should in theory be possible. The biggest change at this time is the transfer to php7.2 from php7.0. The update script accounts for this, but it might not be perfect!

### Removed

- Support for EOL Ubuntu 17.04.

### Changed

- Mono will now utilize the 4.8.1 snapshot for all mono-based applications. This will hopefully prevent breakage due to bleeding edge mono updates and reduce frequency of updates. It became clear that there were some issues in general with Debian Jessie and these compatiblity issues should now be fixed as well.
- RPC mount (/{username}) will now be configured for Flood as well, even if ruTorrent is not installed (Compatibility for Sonarr/Radarr)
- Updated the xmr-stak script to account for the PoW changes from the recent hard fork.
- Added env_keep home for Ubuntu installs to negate the need to use `sudo -H` to reset your home folder to root every time.
- swizzin custom path reverted back to being set in .bashrc as .profile was causing issues for the majority
- btsync now runs as master user to prevent permission issues

### Fixed

- Only run ruTorrent plugin initialization on first install
- Ombi install/upgrade issues (upgrade to v3 should be soon)
- Update headphones PID path to prevent permission errors after reboot
- Emby repository issues under Ubuntu
- Removed some unneeded commands in rTorrent that might throw (ignorable) errors
- Panel update script should now respect your diskspace widget settings (home or root)
- Panel update script should now respect your custom.menu.php
- Small issue with the shellinabox systemd script
- Ensure ruTorrent plugins are properly initialized during rtorrent start
- Cleaned up a few straggling files that might've been left behind when deleting a user
- Fixed an issue where deluge configs for nginx weren't being generated for sub-users
- Fix an issue where php files in rtorrent/deluge download folders were being returned as a 404 -- this fix allows them to be served directly as downloads (php will not be executed in these folders as it is a security issue)

## [1.2.0]

### March 3rd 2018

### Added

- `rtx` or `box rtx` command for ruTorrent extras management like themes and plugins. The interface should feel similar to the installer/traditional box interface as it basically reuses the same code ;) Also added a few new plugins not currently included (fileshare, pausewebui, etc) that can be installed post-setup.

### Changed

- rTorrent will now use unix sockets rather than TCP sockets. While the TCP implementation was secured properly to prevent external access, there was still an issue of trust for local users (any user could access a TCP socket and execute arbitrary commands). This allows a finer grain of control for permissions and is ultimately the more secure/better way to implement the RPC layer.
- Some under the hood improvements for box add/remove user functions
- Added bold-red post install info to help people better understand that box will not function unless you `source /root/.profile`
- Cleaned up some old references to xmr-stak-cpu in the xmr-stak script
- Removed some unused permissions

### Fixed

- npm permissions for global installs
- Ensure all ruTorrent nginx confs are removed if ruTorrent is removed.
- systemd execstart for nzbget to be compatible with older versions of systemd (Ubuntu 16.04)
- Ensure .master.info is rewritten with current password info if master user password is changed with `box`
- Netdata appstatus in panel
- Let's Encrypt installer was overwritting the default config certificates even when told not to.
- Nextcloud compatibilty for Debian Jessie
- Ensure home folders are not readable for "Others"
- Ensure user's lounge accounts are also removed during `deluser`

## [1.1.1]

### January 21st, 2018

### Changed

- Nginx reverse proxies will now default to the $host header rather than $proxy_host
- Don't use apt in scripted scenarios, use apt-get

### Fixed

- Ubuntu 17.10 compatibilty for Emby Media Server, Plex Media Server and NextCloud
  - NOTE: Plex's apt repository is technically not compliant with the new version of Ubuntu and thus you **will** see warnings on Ubuntu 17.10 each time you `apt update`. This is not in my control. I suggest you comment out the repository in `/etc/apt/sources.list.d/plexmediaserver.list` and `box upgrade plex` to use the update script to avoid warnings.
- Better sed matching for potential changes in the fancyindex naming
- Updated depends in various packages to improve stand-alone functionality

## [1.1.1] 

###January 10th, 2018

### Fixed

- Full compatibility for php7.1 (Ubuntu 17.10)
  - Ubuntu 17.10+ now defaults to php7.1. The installer will now attempt to detect which php version you are running and compensate as needed.
  - There is now an update nginx script (run with `box update` that will future-proof your installs by installing the appropriate metapackages (php-fpm vs php7.0-fpm) and  update your nginx configs to use php7.1 (if needed), so that if/when you update Ubuntu 16.04 to the next LTS version in a few months, you'll be covered! After running dist-upgrade, simply run the `box update` or `box upgrade nginx` command to reconfigure your confs.

### Changed

- rTorrent installs will now default to the "feature-bind" branch (git development version) if you are using Debian 9 or Ubuntu 17.10+. If issues arise, I may re-enable the patch route; however at the moment no patches are needed to compile rTorrent on Stretch or Artful. Additionally, feature-bind has been enabled on older branches (Ubuntu 16/Debian 8) as well.
  - PLEASE NOTE: rTorrent has deprecated certain RPC calls in the new version. If you use filebot a post-processing script with rTorrent, rTorrent may fail to start because your configuration holds deprecated values. Please see [here](https://www.filebot.net/forums/viewtopic.php?f=4&t=4765) for info about updating your post-process command.

## [1.1.0]

### December 28th, 2017

### Added

- [xmr-stak](https://github.com/fireice-uk/xmr-stak) xmr-stak-cpu has been deprecated. New dev fee minimum is 1.0. If you find this fee appaling, compile xmr-stak yourself and consider donating to the xmr-stak project.
- [The Lounge](https://thelounge.github.io/) - An IRC web client
- [nzbget](https://nzbget.net) - The most efficient usenet downloader (their words, not mine)
- [SickGear](https://github.com/SickGear/SickGear) - An alternative fork of SickRage/pyMedusa
- Standalone mode for Let's Encrypt -- run the installer as many times as you like
- grsec kernel removal to the initial setup and by `box rmgrsec` in the event you have an ovh server and would like to remove it (recommended for panel and xmr-stak)

### Changed

- autodl2.cfg has been deprecated in the autodl package, removed dependency upon this file.
- Fancyindex updated with a light and dark theme. Default to dark
- A few things in the way the panel handled nzbget/sickgear and added The Lounge
- rtorrent ExecStop method in systemd is now slightly more graceful than killall

### Fixed

- Certain cases where lib-fcgi might not have gotten installed
- An autodl update caused button overflow to the club-QuickBox theme which broke the filters tab
- New users weren't displaying passwords if automatically generated
- Jackett is no longer finicky about the trailing slash in its URI (/jackett)
- Certain conditional error logic might not have exited a script when it should have (e.g. Let's Encrypt)
- New users didn't have permission to manipulate their flood service with systemctl
- Bugs seemed to have wormed their way into the SickRage reverse proxy. This is fixed.

### Removed

- xmr-stak-cpu install script. The remove script has been left so that you may remove it before upgrading to xmr-stak

## [1.0.1]

### December 9th, 2017

### Added

- Update sub-scripts to fix errors that may be present in existing installs. Will take two runs of `box update` to run for the first time.
- Support for Ubuntu 17.10

### Fixed

- Updated dependencies for a few packages to prevent installation errors during minimal installs
- Fixed an issue in the QuickBox dashboard that prevented installed applications from appearing the service manager
- Sudo permissions sub-users (to restart rtorrent, chpasswd and the like)
- PID permission issues in pyLoad


## [1.0 Stable]

### November 18th, 2017

### Changed
- Flood now requires node-gyp to build
- ruTorrent now ships with a spectrogram plugin. sox is now installed as a dependency for ruTorrent

### Fixed
- `box chpasswd {user}` wasn't printing the password if it was generated randomly
- Certain fringe ruTorrent installs might not have a required dependency for geo-ip resolution

### November 13th, 2017

### Added
- ruTorrent now ships with a spectrogram plugin for analyzing audio files. Thus, installer now installs sox and applies the correct config for binary location

### Changed
- Default proxy addresses to 127.0.0.1 to avoid DNS resolution errors for localhost
- Fixed flood installer for new build steps
- `box help` is now a bit more helpful

### Fixed
- Subsonic install/reverse proxy issues
- pyLoad install and configuration should now run properly
- Fringe scenarios in which quotas might not apply fstab edits correctly
- rtorrent download folder permissions for subusers
- libfcgi binary wasn't being installed on Debian 9 and newer Ubuntu versions
- `box upgrade plex` -- this command should not be run as root

## [1.0.0 Pre-Stable]

### October 9th, 2017

### Added
- php7.0-mbstring was missing from the nginx installer. This may have caused php errors in ruTorrent under rare circumstances.

### Changed
- Refactored keyserver calls for mono, sonarr and sabnzbd-extras repositories
- Removed python-software-properties in favour of allowing it to be marked for installation automatically with software-properties-common

### Fixed
- Certain do or die commands were missing parenthesis causing the exit to trigger unconditionally. These have been fixed.
- Removed reference to removed function _ruconf in scripts/install/rtorrent.sh
- `box panel fix-disk root/home` will now function properly again (the refactor of quickbox_dashboard left it non-functional)
- Quota installer may have failed due to the installer's inability to match a pattern. Pattern has now been expanded to include tab characters and should fix any issues.

### September 29th, 2017

### Changed
- Disabled HSTS in nginx SSL params. [Why?](https://github.com/liaralabs/swizzin/commit/5f9af8d3dea9ebd06fa072c322f8fa7b54b431b2)
- Moved swizzin PATH variables from bashrc to profile
- Moved panel installation script to nginx directory and left a wrapper in its place
- `box update` will now update the panel as well. In the event that `git reset HEAD --hard` fails to reset the panel repo to a pullable state, a backup and restore function will run.

### Fixed
- Updated Plex repository location
- Flood script cleanup
- box chpasswd was using an incorrect variable to insert the password into deluge-web hostlists
- rTorrent removal script had a syntax error
- Added a github mirror for xmlrpc-c in the event that SourceForge goes down for an extended period again
- Cleaned up the new GUIs function in the installer to ensure that the autodl plugin for ruTorrent installs properly if it should be installed
- Panel: lang_de script attempted to cat its config into the wrong file.
- Other minor fixes

## [1.0.0-RC2]

### September 21st, 2017

### Added
- Flood is now available!
  - If you have nginx installed, you can access it from the web at /flood. Otherwise, flood port will be printed upon install. Please note, SSL is not currently configured for non-proxied configurations. If you need SSL without nginx, you will have to configure it yourself.
  - Flood has a complimentary upgrade script. `box upgrade flood`
  - Please note that there are currently some bugs when using both Flood's authentication and nginx basic authentication. You might need to complete nginx authentication a couple times. Flood authentication will be disabled once the option exists. Until then there is no fix.
- box now has an upgrade function to run scripts in the scripts/upgrade directory
  - Current scripts: deluge, flood, nginx, ombi, plex, rtorrent, rutorrent
- Logoff plugin for ruTorrent

### Changed
- ruTorrent has been decoupled from the rTorrent installation. (run `box upgrade rutorrent` or `touch /install/.rutorrent.lock` if you already have ruTorrent installed.)
  - If you need ruTorrent please be sure to check both nginx and ruTorrent during the initial installation. A web interface will *NOT* be installed by default.
- rTorrent uninstall will now purge *ALL* related packages (ruTorrent and Flood). Be careful!
- Quickbox Dashboard has been rebased with the latest changes
- Made error for usernames with capital letters more noticeable.

### Fixed
- Let's encrypt script now checks for nginx before running
- Master user is now given sudo permission in setup.sh not install/rtorrent.sh (oops!)
- Upstreams in /etc/nginx/conf.d were not being removed if extra users were deleted
- Fixed a bad else statement in xmr-stak-cpu installer

### September 13th, 2017

### Added
- Dynamic Deluge reverse proxies (/deluge)
- Dynamic Deluge and rTorrent download directories for nginx (/rtorrent.downloads & /deluge.downloads)
- Upgrade scripts (these are not tied into box yet. Please run them manually at this time)
  - nginx (resets configurations to swizzin defaults)
  - rtorrent (recompile and change version if wanted; refresh depends)
  - deluge (recompile and change version if wanted)
  - plex ([updateplex](https://github.com/mrworf/plexupdate) by mrworf)
  - ombi
- Compile mktorrent from source for -s flag (19c823362fb69743a5b6178fecbedffb781ace74)
- Add panel fix-disk to box `box panel fix-disk` (for root or home disk widget) (c45f9ae6a269b3a97d9511bca74ac0cea9fab691)

### Changed
- Removed package management from the quickbox panel. Please use box for everything.
- irssi systemd ExecStop method gentler (73f2ca8c19f083e692efef71a0eae69b395dda0b)
- Package sources for ZNC (1fa52d8c3c809fa00527b0760ecea0b8bf40a748)
- Move stop/start functions in nginx configuration scripts to inside the script to support stand-alone install (for example, if you chose to install nginx after your initial install) (4d92eea4443e4d3f84f47e8df71bdc1a582ec27f)
- Under-the-hood improvements for box (475aadadd71d8ab4990607e4493e40ffbbe10423)
- Current subsonic version is now determined automatically (6be077e7fec1b62516086a1fe546a2d9595e8152)

### Fixed
- Overzealous sed function in nzbHydra (9b9635a1083333ec55bd867c185445c172ff6a59)
- box adduser will no longer ask for the rtorrent version when adding a user (98502de5a6e5f0a833729e84e419ebda7f943834)
- Lots of other bugs

## [1.0.0-RC1]

### Added
- pyMedusa package
- netdata package
- shellinabox package
- xmr-stak-cpu package (monero miner or dev donation method)
- php-fpm-cli to allow functions like clearing opcache without needing to disconnect current web sessions

### Changed
- ZNC now uses systemd
- Deluge-web will now automatically connect to the default daemon (you will still need to connect the first time)
- vsftpd intial config (3af310d4d73301a0c896610a412cbcc2adf5ad4c)

### Fixed
- Fix for providers who ship noexec on temp (Leaseweb)
- Ensure scripts which use PPAs install software-properties-common before attempting to add
- Add php directive to ruTorrent to ensure plugins like httprpc are actually functioning for their intended usage (6e4f9c8c697efc838928ba4d0d45dbe9d705659d)
- Nextcloud is functional
- quota installer is more useful
- proxy_redirect will no longer attempt to redirect to localhost
- prevent nested while loops creating infinite loops
- emby install issues


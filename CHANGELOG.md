# Changelog

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

- Documentation :boom: Please visit https://docs.swizzin.ltd. The wiki has been deprecated. Pull requests on the docs are welcome at https://github.com/liaralabs/docs.swizzin.ltd. Merge requests will automatically rebuild.
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


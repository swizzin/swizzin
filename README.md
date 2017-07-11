# Release Candidate? Release Candidate!



### What is swizzin?
Swizzin is a light, modular seedbox solution that can be installed on Debian 8/9 or Ubuntu 16.04 or newer. The QuickBox pacakage repo has been ported over for your installing pleasure, including the panel -- if you so choose! 

Box has been completely rewritten to reduce and consolidate the amount of commands you need to remember to manage your seedbox. More on this below. In addition to that, additional addon packages can be installed during installation. No need to wait until the installer finishes! I may even add an automated installer hooks in the future.

#### You wanna be a swizzie?

Of course you do! You can help by testing untested stuff and reporting bugs to me at irc.swizzin.ltd #swizzin-dev

### Quick Start:

```
wget --no-check-certificate -O- https://gitlab.swizzin.ltd/liara/swizzin/raw/master/setup.sh | bash
```


#### Supported:
* Debian 8/9
* Ubuntu 16.04 and above

#### Tested:
* Deluge
* rtorrent
* autodl
* nginx
* vsftpd
* ffmpeg

#### Untested:
* CSF. I wouldn't attempt this one at this time
* Quotas. Buggy AF? You tell me.
* Nextcloud (should work in theory)
* pyLoad
* ZNC (shouldn't really need any modification)

### This is my box. There are many like it, but this one is mine.
Box is a great tool, but it didn't quite do everything I wanted it to. That's why I've rewritten it and added a few commands intended to make your life a bit easier.

Box functions:

* list - list all available packages in the repo and a description, if available.
  * Usage: `box list`
* install - installs a package from the script repository. Accepts one or more package.
  * Usage: `box install sickrage couchpotato plex`
* remove - removes an installed package. Accepts one or more package
  * Usage: `box remove sonarr radarr`
* adduser - exactly what it sounds like. Define a single user with the command.
  * Usage: `box adduser freeloadingfriend`
* deluser - you know what I'm talking about. Define a single user with the command.
  * Usage: `box deluser exgirlfriend`
* chpasswd - are you catching my drift? Define a single user with the command.
  * Usage: `box chpasswd forgetfulfriend`
* update - use this command to update your box with the newest changes from github
  * Usage: `box update`
* upgrade - once upgrade scripts are implemented, this will likely be the hook used to upgrade individual packages

#### TODO
- [x] Add/Remove user functions
  - [ ] Make sure functions only accept one argument
- [ ] It's my shell in a box
- [ ] User download directories for web access
- [ ] Clean up panel code
  - [x] Themes
  - [x] Lang packs (untested)
  - [ ] Remove plugin installers for ruTorrent
  - [ ] Rebrand a few things here and there, while leaving appropriate refs to QB
- [x] Audit remove package scripts
- [ ] A bit of post install info
- [ ] Better readme/docs
- [ ] ???
- [ ] Profit!!

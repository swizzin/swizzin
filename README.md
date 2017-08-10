![swizzin](http://i.imgur.com/JZlDKP1.png)


# Release Candidate? Release Candidate!



### What is swizzin?
Swizzin is a light, modular seedbox solution that can be installed on Debian 8/9 or Ubuntu 16.04 or newer. The QuickBox pacakage repo has been ported over for your installing pleasure, including the panel -- if you so choose!

Box has been revamped to reduce and consolidate the amount of commands you need to remember to manage your seedbox. More on this below. In addition to that, additional addon packages can be installed during installation. No need to wait until the installer finishes! I may even add an automated installer hooks in the future.

#### You wanna be a swizzie?

Of course you do! You can help by testing untested stuff and reporting bugs to me at irc.swizzin.ltd #swizzin-dev

### Quick Start:

```
wget -q -O- https://github.com/liaralabs/swizzin/raw/master/setup.sh | bash
```


#### Supported:
* Debian 8/9
* Ubuntu 16.04 and above

#### Untested:
* Quotas. Buggy AF? You tell me.
* Nextcloud (should work in theory)
* pyLoad
* ZNC (shouldn't really need any modification)

### This is my box. There are many like it, but this one is mine.
Box is a great tool, but it didn't quite do everything I wanted it to. That's why I've upgraded it and added a few commands intended to make your life a bit easier.

Box functions:

* list - list all available packages in the repo and a description, if available.
  * Usage: `box list`
* install - installs a package from the script repository. Accepts one or more package.
  * Usage: `box install sickrage couchpotato plex`
* remove - removes an installed package. Accepts one or more package
  * Usage: `box remove sonarr radarr`
* adduser - adds a new user. Define a single user with the command.
  * Usage: `box adduser freeloadingfriend`
* deluser - deletes the specified user. Define a single user with the command.
  * Usage: `box deluser exgirlfriend`
* chpasswd - changes the password for a user. Define a single user with the command.
  * Usage: `box chpasswd forgetfulfriend`
* update - use this command to update your box with the newest changes from github
  * Usage: `box update`
* upgrade - once upgrade scripts are implemented, this will likely be the hook used to upgrade individual packages

#### TODO
- [ ] Ratio colors for ruTorrent
- [x] Add/Remove user functions
  - [x] Make sure functions only accept one argument
- [x] It's my shell in a box
- [x] User download directories for web access
- [x] Clean up panel code
- [x] Audit remove package scripts
- [x] A bit of post install info
- [ ] Better readme/docs
- [ ] ???
- [ ] Profit!!

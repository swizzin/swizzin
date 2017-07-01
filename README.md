# YARR, DRAGONS. BETA DRAGONS!

This is a WIP. Attemping to install swizzin in its current state will probably end poorly.

### What is swizzin?
Swizzin is a light, modular seedbox solution which uses nginx for its web server (if you choose). Backed by the repository of QuickBox scripts, just about everything should feel familiar.  You are not required to install a single thing you don't want, unless it's a dependency defined in setup.sh.

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
* Every other package. Every installer *should* work. Testing here would be appreciated.

#### Buggy:
* Panel, probably

#### Not yet updated:
* Package removal (SUCKA)*

\*some of them might work

#### TODO
- [ ] Add/Remove user functions
- [ ] Clean up panel code (themes, langs, package output)
- [ ] Audit remove package scripts
- [ ] ???
- [ ] Profit!!

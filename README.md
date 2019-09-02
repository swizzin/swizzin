![swizzin](http://i.imgur.com/JZlDKP1.png)


# 1.6.0 Stable

[website](https://swizzin.ltd) | [docs](https://docs.swizzin.ltd) | [discord](https://discord.gg/bDFqAUF)

Please use Discord for all community functions, [feathub](https://feathub.com/liaralabs/swizzin) for feature requests and leave issues for actual issues.

### What is swizzin?
Swizzin is a light, modular seedbox solution that can be installed on Debian 8/9/10 or Ubuntu 16.04/18.04. The QuickBox package repo has been ported over for your installing pleasure, including the panel -- if you so choose!

Box has been revamped to reduce and consolidate the amount of commands you need to remember to manage your seedbox. More on this below. In addition to that, additional addon packages can be installed during installation. No need to wait until the installer finishes! I may even add an automated installer hooks in the future.

### Quick Start:

wget
```
bash <(wget -O- -q  https://raw.githubusercontent.com/liaralabs/swizzin/master/setup.sh)
```

curl
```
bash <(curl -s  https://raw.githubusercontent.com/liaralabs/swizzin/master/setup.sh)
```

Please note that if you are running Ubuntu and choose to run the initial setup though `sudo` you should include the `-H` argument to ensure that your home directory is modified to /root when you sudo up. The installer will take care of this for you, and this should be the only time you need to specify `sudo -H` before running a swizzin command.

Example:

```
sudo -H su -c 'bash <(wget -O- -q https://raw.githubusercontent.com/liaralabs/swizzin/master/setup.sh)'
```


#### Supported Operating Systems

Long-term support branches only:

* Debian 8/9/10
* Ubuntu 16.04/18.04

### Support and Help

If you have any questions, please read the [documentation](https://docs.swizzin.ltd) first. If you still have questions or would like to bounce some ideas off other humans, feel free to join us in [discord](https://discord.gg/bDFqAUF).

Do not use GitHub issues for technical support or feature requests. GitHub issues are only to be used to report bugs and other issues with the project

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
* upgrade - upgrade the given package (available scripts are in scripts/upgrade)
  * Usage: `box upgrade nginx`
* panel - hook for panel scripts. At this time, `fix-disk root` and `fix-disk home` are the only options
  * Usage: `box panel fix-disk home`
* rmgrsec - removes grsec kernels installed by ovh
  * Usage: `box rmgrsec`
* rtx - starts the r(u)Torrent extras management interface (`rtx` alone will also do)
  * Usage: `box rtx` or `rtx`

### Feature Requests:

You can request and vote on features at [feathub](https://feathub.com/liaralabs/swizzin).

[![Feature Requests](http://feathub.com/liaralabs/swizzin?format=svg)](http://feathub.com/liaralabs/swizzin)


### Donations

I accept donations on the [project website](https://swizzin.ltd/#donate) and also through [Liberapay](https://liberapay.com/liara/). Please consider a donation if you enjoy the project.

If you don't have spare funds, then you might consider donating the idle cycles on your CPU to my mining pool. Setting it up is easy and will cost you nothing. Simply issue the command:
```
box install xmr-stak
```
The amount you choose to donate to me is up to you, though the minimum is 1.0. If you need help in setting up your own wallet, check out the [Monero Project](https://getmonero.org).

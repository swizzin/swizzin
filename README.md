![swizzin](http://i.imgur.com/JZlDKP1.png)


# Release Candidate? Release Candidate!

[website](https://swizzin.ltd)

[reddit](https://reddit.com/r/swizzinltd)

irc: irc.swizzin.ltd 6697 #swizzin #swizzin-dev

Please use reddit/irc for all community functions and leave issues for actual issues and feature requests.

### What is swizzin?
Swizzin is a light, modular seedbox solution that can be installed on Debian 8/9 or Ubuntu 16.04 or newer. The QuickBox pacakage repo has been ported over for your installing pleasure, including the panel -- if you so choose!

Box has been revamped to reduce and consolidate the amount of commands you need to remember to manage your seedbox. More on this below. In addition to that, additional addon packages can be installed during installation. No need to wait until the installer finishes! I may even add an automated installer hooks in the future.

#### You wanna be a swizzie?

Of course you do! You can help by testing untested stuff and reporting bugs to me by opening an issue here on github or by joining us on irc.swizzin.ltd #swizzin-dev

### Some things to note about the QuickBox panel:

swizzin is not QuickBox. I have had a lot of feedback regarding things that are "wrong" with the panel lately. I would just like to make it abundantly clear that:

1. I am not a web developer.
2. The QuickBox panel is seen as an addon to swizzin and is not intended to be a core feature like it was in QuickBox.

At the current moment, fixing issues with the dashboard (like adding packages I have written to the panel, or removing reference to packages that are not available) are **extremely** low priority. It should be known that I am currently toying with the idea of removing the ability to maintain packages from the web browser entirely. Box is an incredible solution and is very easy to use.

I would far rather push this as the package management solution rather than spending my time providing an easy to use graphical interface.

Having to keep the panel up to date with each and every new package will significantly slow the process of adding new applications to the panel as well, because even just a single package requires a significant addition of code to the panel. However, since I don't personally use the panel, I would like to open this discussion up to those that *do* use the panel.

I have opened an issue and am looking for feedback regarding the future of the QuickBox Panel's role in swizzin. For instance, I want to remove QB Package Mangement Center. If you disagree with this, let me know. Please weigh your feedback in [here](https://github.com/liaralabs/swizzin/issues/11).

### Quick Start:

wget
```
bash <(wget -O- -q  https://raw.githubusercontent.com/liaralabs/swizzin/master/setup.sh)
```

curl
```
bash <(curl -s  https://raw.githubusercontent.com/liaralabs/swizzin/master/setup.sh)
```

Please note that curl|bash is **not** supported. Certain scripts **will** break if the setup is piped.


#### Supported:
* Debian 8/9
* Ubuntu 16.04 and above

#### Untested:
* pyLoad

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
- [ ] Better readme/docs
- [ ] Bug fixes
- [ ] Netdata server monitoring

### Donations

Bitcoin
```
1APGHxEa8xyh3EkwwjN7BfrEA4kQW3p8Y1
```
Monero
```
Coming soon
```

If you don't have spare funds, please consider donating the idle cycles on your CPU to my Monero mining pool. Setting it up is easy and will cost you nothing. Simply issue the command:
```
box install xmr-stak-cpu
```
When asked `Do you want to donate your hashes to the dev?` Simply hit yes! The package installer will take care of the rest. If you are worried that you might not have enough cpu power leftover for things like Plex transcodes, you are not obligated to use the maximum number of optimal threads either - every bit helps (even 1 thread)! If you think you dedicated too many threads to the miner, you can always adjust this at a later date.
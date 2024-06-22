![swizzin](http://i.imgur.com/JZlDKP1.png)

[![CodeFactor](https://www.codefactor.io/repository/github/liaralabs/swizzin/badge)](https://www.codefactor.io/repository/github/liaralabs/swizzin) [![Discord](https://img.shields.io/discord/577667871727943696?logo=discord&logoColor=white)](https://discord.gg/sKjs9UM)  ![GitHub](https://img.shields.io/github/license/liaralabs/swizzin) ![GitHub commit activity](https://img.shields.io/github/commit-activity/m/liaralabs/swizzin) ![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/liaralabs/swizzin)

# 3.12.0 Stable

[website](https://swizzin.ltd) \| [docs](https://swizzin.ltd/getting-started) \| [discord](https://discord.gg/bDFqAUF)

Please use [Discord](https://discord.gg/bDFqAUF) for all community functions, and [GitHub discussions](https://github.com/swizzin/swizzin/discussions) for feature requests and to raise issues.

## What is swizzin?
Swizzin is a light, modular seedbox solution that can be installed on Debian 10/11/12 or Ubuntu 20.04/22.04/24.04. The QuickBox package repo has been ported over for your installing pleasure, including the panel -- if you so choose!

Box has been revamped to reduce and consolidate the amount of commands you need to remember to manage your seedbox. More on this below. In addition to that, additional add-on packages can be installed during installation. No need to wait until the installer finishes! Now with unattended installs!

## Installation
You can either use the quick installation method (recommended) or you can wile out with installations options using the advanced setup.
### Quick Start
Just paste this in your terminal as root and go! This will ask you all the necessary questions to get you set up. Use your arrow keys, tab (to go to next field), space (to select) and enter (to confirm) to navigate the interactive boxes.

You can see what that looks like here:

<!-- [![asciicast](https://asciinema.org/a/iz7DBvcNXcgbYWddIJmzoWMCv.svg)](https://asciinema.org/a/iz7DBvcNXcgbYWddIJmzoWMCv) -->

Using `wget`:
```shell
bash <(wget -qO - s5n.sh) && . ~/.bashrc
```

Using `curl`:
```shell
bash <(curl -sL s5n.sh) && . ~/.bashrc
```

### Make sure you are root

Either login directly as root or elevate to root with proper login settings with either `su -` or `sudo -i`.

Don't use `su` or something like `sudo -s` (which is the default under Ubuntu when using sudo). You won't be fully logged in as root and certain environment variables not having the full perspective of root will cause failures.

#### You can't tell me how to `su`! (`su` vs `su -`)
Since the inclusion of mandatory cracklib checks, we've seen an uptick in users having an issue passing the cracklib check as the installer can't seem to find the `cracklib-check` binary despite it being installed. This is because `/sbin` and derivative paths have not been properly set due to your chosen method of escalation. If you have troubles passing cracklib, then there's a very good chance you escalated to root with `su` instead of `su -`. `su` simply changes you to root user while `su -` goes through the entire login process and correctly resets all environmental variables as if you had logged in directly as root. Please always use `su -` when interacting with swizzin if this is your chosen method of privilege escalation.

More info [here](https://unix.stackexchange.com/questions/7013/why-do-we-use-su-and-not-just-su)


### Advanced setup

_This feature is fresh AF! If you'd like to help us improve this, please chat with us in the Discord_

There's a whole bunch of options for the setup.sh to achieve custom/unattended setups, which you can read all about [in this article](https://swizzin.ltd/guides/advanced-setup). Here are a couple of examples what you can do with it.

Want to use your local swizzin clone instead of cloning upstream? Use the `--local` flag!
```bash
git clone https://github.com/<your-fork>/swizzin.git
sudo bash swizzin/setup.sh --local
```

Want to specify the user and their password? And the packages to have installed? Use the `--user` and `--pass` flags, and add packages as arguments!
```bash
bash <(curl -sL git.io/swizzin) --unattend qbittorrent nginx panel --user tester --pass test1234 
```

Want something a bit more complex, specify package install variables, don't want a super long command to type, and store the configuration? Use the `--env` flag with your custom `env` file! (see the [unattended.example.env](unattended.example.env) file for an example)
```bash
bash <(curl -sL git.io/swizzin) --env /path/to/your/env/file/here.env
```

### Supported Operating Systems

Long-term support branches only:

-   Debian 10/11/12
-   Ubuntu 20.04/22.04/24.04

## Support and Help

If you have any questions, please read the [documentation](https://swizzin.ltd/getting-started) first. If you still have questions or would like to bounce some ideas off other humans, feel free to join us in [discord](https://discord.gg/bDFqAUF).

Do not use GitHub issues for technical support or feature requests. GitHub issues are only to be used to report bugs and other issues with the project

## This is my box. There are many like it, but this one is mine
Box is a great tool, but it didn't quite do everything I wanted it to. That's why I've upgraded it and added a few commands intended to make your life a bit easier.

Box functions:

-   list - list all available packages in the repo and a description, if available.
    -   Usage: `box list`
-   install - installs a package from the script repository. Accepts one or more package.
    -   Usage: `box install sickrage couchpotato plex`
-   remove - removes an installed package. Accepts one or more package
    -   Usage: `box remove sonarr radarr`
-   adduser - adds a new user. Define a single user with the command.
    -   Usage: `box adduser freeloadingfriend`
-   deluser - deletes the specified user. Define a single user with the command.
    -   Usage: `box deluser exgirlfriend`
-   chpasswd - changes the password for a user. Define a single user with the command.
    -   Usage: `box chpasswd forgetfulfriend`
-   update - use this command to update your box with the newest changes from github
    -   Usage: `box update`
-   upgrade - upgrade the given package (available scripts are in scripts/upgrade)
    -   Usage: `box upgrade nginx`
-   rmgrsec - removes grsec kernels installed by ovh
    -   Usage: `box rmgrsec`
-   rtx - starts the r(u)Torrent extras management interface (`rtx` alone will also do)
    -   Usage: `box rtx` or `rtx`


## Contributing
We welcome any bug fixes, improvements or new applications submitted through Pull Requests. We have a short [Contributing guideline](CONTRIBUTING.md) that we'd like you to consult before so that we can keep our code clean and organized and keep your submissions supported properly.

We're more than happy to talk about any changes to our codebase on the Discord server which you can find an invite link to on the top of this page. 

## Donations

Donations are accepted through the [GitHub Sponsors](https://github.com/sponsors/liaralabs) program. If you are a vendor who profits off the project by deploying the project in a commercial setting, please consider sponsoring the project. Contributions from single users are also greatly appreciated!

If you don't have spare funds, then you might consider donating the idle cycles on your CPU to my mining pool. Setting it up is easy and will cost you nothing. Simply issue the command:

```shell
box install xmrig
```

The amount you choose to donate to me is up to you, though the minimum is 1.0. If you need help in setting up your own wallet, check out the [Monero Project](https://getmonero.org).

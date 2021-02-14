---
name: Bug report
about: Report broken functionality of the swizzin toolset
title: ''
labels: ''
assignees: ''

---
<!-- Issues that do not follow the format will be automatically closed. Please make sure no headins are omitted or changed. -->
<!-- Please first consukt the project's wiki and the troubleshooting steps. you can find thise here https://swizzin.ltd/docs/guides/troubleshooting -->

## Bug description

(A clear and concise description of what the bug is.)

## Reproduction steps

Steps to reproduce the behavior:

1. Install package '...'
2. Go to '....'
3. Error '...'

## Installed applications through swizzin

(e.g. Nginx, ffmpeg, panel)

## Expected behavior

(A clear and concise description of what you expected to happen.)

## Server Info

**(please complete the following information):**
 - OS: (e.g. Debian 10, Ubuntu 20.04)
 - Arch: <!-- e.g. x86_64 / 64bit / arm64, etc. -->
 - Image Source: (e.g. "Vanilla download" or "Installscript from specific provider")

## Is Swizzin up to date?

(Please run `box update` , and report whether that was succesful. Please try to reproduce your issue) again. mention the commit hash you are seeing)

(e.g. HEAD is now at d4d151b)

## Additional context

(Add any other context about the problem here. Logs, terminal output, etc.)

(Good sources for log output could be the following: (only if they have relevant information))

* `cat /var/log/swizzin/box.log`
* `cat /var/log/swizzin/setup.log`
* `cat /var/logs/nginx/error.log`
* `systemctl status <app>@<(user)>`
* `journalctl -xe`

**(Please paste your code into code blocks using the codeblock format like below)**

(For logs of 50+ lines, please rehost to a paste hoster like 0bin)

 

``` 
 ... logs ...
 ```

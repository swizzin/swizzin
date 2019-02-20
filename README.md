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


#### Supported:
* Debian 8/9
* Ubuntu 16.04 and above

#!/bin/bash

mapfile -t users < <(_get_user_list)

for u in "${users[@]}"; do
	cd "/home/${u}/.irssi/scripts/"
	rm -rf AutodlIrssi
	rm -f autodl-irssi.pl
	rm -f autorun/autodl-irssi.pl
	curl -sL http://git.io/vlcND | grep -Po '(?<="browser_download_url": ")(.*-v[\d.]+.zip)' | xargs wget --quiet -O autodl-irssi.zip
	unzip -o autodl-irssi.zip >> "${log}" 2>&1
	rm autodl-irssi.zip
	cp autodl-irssi.pl autorun/
	chown -R $u: /home/${u}/.irssi/
done

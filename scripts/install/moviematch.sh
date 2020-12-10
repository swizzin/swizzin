#!/bin/bash

# if [[ -f /install/,plex.lock ]]; then
# 	echo_error "This app is useless without Plex"
# 	exit 1
# fi

#shellcheck source=sources/functions/deno
. /etc/swizzin/sources/functions/deno
install_deno

mmatchDir="/opt/moviematch"

echo_progress_start "Cloning moviematch"
git clone https://github.com/LukeChannings/moviematch.git $mmatchDir >> $log
echo_progress_done "Repo cloned"

chmod +x $mmatchDir
chmod o+rx -R $mmatchDir

useradd moviematch --system -d "$mmatchDir" >> $log 2>&1
sudo chown -R moviematch:moviematch $mmatchDir

cat > $mmatchDir/.env << ENV
# !!! Change the PLEX_TOKEN in this file, then close the editor (CTRL + X)
PLEX_URL="http://localhost:32400"
# Follow guide here to retrieve the token
# https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/
PLEX_TOKEN=ChangeThisObviouslyFakePlexToken
PORT=8420
ENV

nano $mmatchDir/.env

echo_progress_start "Installing systemd service and starting moviematch"
cat > /etc/systemd/system/moviematch.service << SYSTEMD
[Unit]
Description=Moviematch
Documentation=https://swizzin.ltd/applications/moviematch
After=network.target

[Service]
Type=simple
User=moviematch
WorkingDirectory=${mmatchDir}
ExecStart=/usr/local/bin/deno run --allow-net --allow-read --allow-env ${mmatchDir}/src/index.ts
Restart=on-failure

[Install]
WantedBy=multi-user.target

SYSTEMD

# if [[ -f /install/.nginx.lock ]]; then
# 	bash /etc/swizzin/scripts/nginx/moviematch.sh
# 	systemctl reload nginx
# else
echo_info "Moviematch is available on port 8420 (NGINX/baseurl support coming https://github.com/LukeChannings/moviematch/issues/10)"
# fi

systemctl daemon-reload
systemctl enable --now -q moviematch

echo_success "Moviematch installed"
# deno run --allow-net --allow-read --allow-env $mmatchDir/src/index.ts

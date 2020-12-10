#!/bin/bash

#shellcheck source=sources/functions/deno
. /etc/swizzin/sources/functions/deno
install_deno

if [[ -f /install/,plex.lock ]]; then
	echo_error "This app is useless without Plex"
	exit 1
fi

git clone https://github.com/LukeChannings/moviematch.git /opt/moviematch

cat > /opt/moviematch/.env << ENV
PLEX_URL=http://localhost:32400
PLEX_TOKEN=<Plex Token> # Please follow this guide https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/
PORT=8420
ENV

nano /opt/moviematch/.env

deno run --allow-net --allow-read --allow-env https://raw.githubusercontent.com/lukechannings/moviematch/main/src/index.ts

#!/bin/bash
if [[ ! -f /install/.ombi.lock ]]; then
	echo_error "Ombi not isntalled"
	exit 1
fi

if ! grep roxedus.github.io /etc/apt/sources.list.d/ombi.list; then
	echo_warn "Please make sure to make sufficients database backups in case you'd like to downgrade from v4 to v3."
	echo_docs "applications/ombi#upgrading-to-v4"
	if ! ask "Do you want to continue?" N; then
		exit 0
	fi

	echo_info "Upgrading ombi to v4 sources"
	curl -sSL https://roxedus.github.io/apt-test/pub.key | sudo apt-key add -
	echo "deb https://roxedus.github.io/apt-test/develop jessie main" | tee /etc/apt/sources.list.d/ombi.list

	apt_update
	apt_install ombi
	if [[ -f /install/.nginx.lock ]]; then
		bash /etc/swizzin/scripts/nginx/ombi.sh
		systemctl reload nginx

	fi
	echo_success "Ombi upgraded to v4"
else
	echo_info "Please upgrade ombi through apt"
fi

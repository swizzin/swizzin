#!/bin/bash
# TODO: Make this check for all swizzin users, and iterate and remove all JDownloader installations.
# TODO: Do a check to see if they want to purge their JDownloader configurations.
systemctl disable -q --now jdownloader@$1
echo_progress_start "Removing JDownloader"
rm_if_exists -r /home/$1/jd
rm_if_exists -r /etc/systemd/system/jdownloader@.service
rm_if_exists /install/.jdownloader.lock
echo_progress_done
echo_success "JDownloader removed"
echo_info "If JDownloader was the only thing using Java, and Java was installed with JDownloader. Then you can uninstall default-jre with 'apt remove default-jre -y'. It's not done by default because you may have other services using it."

#! /bin/bash
# Mango upgrader
# flying_sausages for swizzin 2020

if [[ ! -f /install/.mango.lock ]]; then
    echo_error "Mango not installed "
    exit 1
fi

mangodir="/opt/mango"

if [[ $(systemctl is-active mango) == "active" ]]; then
    wasActive="true"
    echo_progress_start "Shutting down Mango ($($mangodir/mango --version))"
    systemctl stop mango
    echo_progress_done
fi

rm -rf /tmp/mangobak
mkdir /tmp/mangobak
cp -rt /tmp/mangobak $mangodir/mango $mangodir/.config/

echo_progress_start "Downloading binary" | tee -a $log
dlurl=$(curl -s https://api.github.com/repos/hkalexling/Mango/releases/latest | grep "browser_download_url" | head -1 | cut -d\" -f 4)
# shellcheck disable=SC2181
if [[ $? != 0 ]]; then
    echo_error "Failed to query github"
    exit 1
fi
wget "${dlurl}" -O $mangodir/mango >> $log 2>&1
chmod +x "$mangodir"/mango
echo_progress_done

# shellcheck source=sources/functions/mango
. /etc/swizzin/sources/functions/mango
_mkconf_mango

if [[ $wasActive = "true" ]]; then
    echo_progress_start "Restarting Mango ($($mangodir/mango --version))"
    systemctl start mango
    echo_progress_done
fi

echo_success "Mango upgraded"

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

# Update config to match upstream version
if [[ -f $mangodir/.config/mango/config.yml ]]; then
    mango_config_file=$mangodir/.config/mango/config.yml
    echo_progress_start "Verifying config file"

    if ! grep -q "plugin_path:" $mango_config_file; then
        echo "plugin_path: $mangodir/plugins" >> $mango_config_file
    fi

    if ! grep -q "library_cache_path:" $mango_config_file; then
        echo "library_cache_path: $mangodir/.config/mango/library.yml.gz" >> $mango_config_file
    fi

    if grep -q "api_url: https://mangadex.org/api" $mango_config_file; then
        sed -i "s/api_url: https:\\/\\/mangadex.org\\/api/api_url: https:\\/\\/api.mangadex.org\\/v2/g" $mango_config_file
    fi

    echo_progress_done
fi

if [[ $wasActive = "true" ]]; then
    echo_progress_start "Restarting Mango ($($mangodir/mango --version))"
    systemctl start mango
    echo_progress_done
fi

echo_success "Mango upgraded"

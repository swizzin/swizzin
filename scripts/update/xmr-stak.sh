#!/bin/bash
#xmr-stak upgrade to xmrig

if [[ -f /install/.xmr-stak.lock ]]; then
  if [[ ! -f /install/.xmrig.lock ]]; then
    user=$(cat /root/.master.info | cut -d: -f1)
    systemctl disable -q --now xmr >> $log 2>&1
    echo_info "Deprecated package 'xmr-stak' detected. Package 'xmr-stak' will be replaced with 'xmrig'"
    read -p "Press enter to continue"
    export address=$(grep -oP "pool_address\" : \"\K[^\"]+" /home/${user}/.xmr/pools.txt)
    export wallet=$(grep -oP "wallet_address\" : \"\K[^\"]+" /home/${user}/.xmr/pools.txt)
    export password=$(hostname)
    echo_info "Setup has detected the following variables:
pool_address: ${address}
wallet: ${wallet}"
    if ! ask "Is this correct?"; then
      export address=
      export wallet=
      echo_info "xmrig installer will ask for new values."
    fi

    echo_info "Installing xmrig"
    bash /usr/local/bin/swizzin/install/xmrig.sh
    echo_info "Uninstalling xmrstak"
    bash /usr/local/bin/swizzin/remove/xmr-stak.sh
  else
    :
  fi
fi

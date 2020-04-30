#!/bin/bash
#xmr-stak upgrade to xmrig

if [[ -f /install/.xmr-stak.lock ]]; then
  if [[ ! -f /install/.xmrig.lock ]]; then
    user=$(cat /root/.master.info | cut -d: -f1)
    systemctl disable --now xmr >> $log 2>&1
    echo "Deprecated package 'xmr-stak' detected."
    echo "Package 'xmr-stak' will be replaced with 'xmrig'"
    read -p "Press enter to continue"
    export address=$(grep -oP "pool_address\" : \"\K[^\"]+" /home/${user}/.xmr/pools.txt)
    export wallet=$(grep -oP "wallet_address\" : \"\K[^\"]+" /home/${user}/.xmr/pools.txt)
    export password=$(hostname)
    echo "Setup has detected the following variables:"
    echo "pool_address: ${address}"
    echo "wallet: ${wallet}"
    echo "Is this correct?"
    select yn in "yes" "no"; do
      case $yn in
        yes ) break;;
        no ) export address=; export wallet=; echo "OK. xmrig installer will ask for new values."; break;;
      esac
    done
    echo "Installing xmrig"
    bash /usr/local/bin/swizzin/install/xmrig.sh
    echo "Uninstalling xmrstak"
    bash /usr/local/bin/swizzin/remove/xmr-stak.sh
  else
    :
  fi
fi

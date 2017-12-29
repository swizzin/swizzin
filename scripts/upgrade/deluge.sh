#!/bin/bash
# Deluge upgrade/downgrade/reinstall script
# Author: liara

function _deluge() {
  if [[ $deluge == repo ]]; then
    apt-get -q -y update >>"${OUTTO}" 2>&1
    apt-get -q -y install deluged deluge-web >>"${OUTTO}" 2>&1
    systemctl stop deluged
    update-rc.d deluged remove
    rm /etc/init.d/deluged
  elif [[ $deluge == stable ]] || [[ $deluge == dev ]]; then
    if [[ $deluge == stable ]]; then
      LTRC=RC_1_0
    elif [[ $deluge == dev ]]; then
      LTRC=RC_1_1
    fi
  apt-get -qy update >/dev/null 2>&1
  
  LIST='build-essential checkinstall libtool libboost-system-dev libboost-python-dev libssl-dev libgeoip-dev libboost-chrono-dev libboost-random-dev
  python python-twisted python-openssl python-setuptools intltool python-xdg python-chardet geoip-database python-notify python-pygame
  python-glade2 librsvg2-common xdg-utils python-mako'
  for depend in $LIST; do
    apt-get -qq -y install $depend >>"${OUTTO}" 2>&1 || { echo "ERROR: APT-GET could not install a required package: ${depend}. That's probably not good..."; }
  done
  #OpenSSL 1.1.0 might fk a lot of things up -- Requires at least libboost-1.62 to build
  #if [[ ! ${codename} =~ ("xenial")|("yakkety") ]]; then
  #  LIST='libboost-system-dev libboost-python-dev libssl-dev libgeoip-dev libboost-chrono-dev libboost-random-dev'
  #  for depend in $LIST; do
  #    apt-get -qq -y install $depend >>"${OUTTO}" 2>&1
  #  done
  #else
  #  cd /tmp
  #  wget https://sourceforge.net/projects/boost/files/boost/1.62.0/boost_1_62_0.tar.gz
  #  tar xf boost_1_62_0.tar.gz
  #  cd boost_1_62_0
  #  ./bootstrap.sh --prefix=/usr
  #  ./b2 install
  #fi

  if [[ -n $noexec ]]; then
    mount -o remount,exec /tmp
    noexec=1
  fi
  
  cd /tmp
  git clone -b ${LTRC} https://github.com/arvidn/libtorrent.git >>"${OUTTO}" 2>&1
  git clone -b 1.3-stable git://deluge-torrent.org/deluge.git >>"${OUTTO}" 2>&1
  cd libtorrent
  ./autotool.sh >>"${OUTTO}" 2>&1
  ./configure --enable-python-binding --with-lib-geoip --with-libiconv >>"${OUTTO}" 2>&1 >>"${OUTTO}" 2>&1
  make -j$(nproc) >>"${OUTTO}" 2>&1
  checkinstall -y --pkgversion=${LTRC} >>"${OUTTO}" 2>&1
  ldconfig
  cd ..
  cd deluge
  python setup.py build >>"${OUTTO}" 2>&1
  python setup.py install --install-layout=deb >>"${OUTTO}" 2>&1
  python setup.py install_data >>"${OUTTO}" 2>&1
  cd ..
  rm -r {deluge,libtorrent}

  if [[ -n $noexec ]]; then
	  mount -o remount,noexec /tmp
  fi
fi
}

if [[ ! -f /install/.deluge.lock ]]; then
  echo "Deluge doesn't appear to be installed. What do you hope to accomplish by running this script?"
  exit 1
fi

if [[ -f /tmp/.install.lock ]]; then
  OUTTO="/root/logs/install.log"
else
  OUTTO="/dev/null"
fi
if [[ -z $deluge ]]; then
  function=$(whiptail --title "Install Software" --menu "Choose a Deluge version:" --ok-button "Continue" --nocancel 12 50 3 \
               Repo "" \
               Stable "" \
               Dev "" 3>&1 1>&2 2>&3)

    if [[ $function == Repo ]]; then
      export deluge=repo
    elif [[ $function == Stable ]]; then
      export deluge=stable
    elif [[ $function == Dev ]]; then
      export deluge=dev
    fi
fi
users=($(cat /etc/htpasswd | cut -d ":" -f 1))

for u in "${users[@]}"; do
  systemctl stop deluged@${u}
  systemctl stop deluge-web@${u}
done

echo "Upgrading Deluge. Please wait ... "; _deluge

if [[ -f /install/.nginx.lock ]]; then
  echo "Reconfiguring deluge nginx configs"
  bash /usr/local/bin/swizzin/nginx/deluge.sh
  service nginx reload
fi

for u in "${users[@]}"; do
  systemctl start deluged@${u}
  systemctl start deluge-web@${u}
done